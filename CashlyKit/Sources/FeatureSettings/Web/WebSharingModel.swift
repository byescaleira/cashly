import CashlyDomain
import CashlyWeb
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class WebSharingModel {
    public enum LinkOutcome: Equatable, Sendable {
        case ignored, invalid, needsPro, confirming, alreadyConnected
    }

    public private(set) var sessions: [WebSession] = []
    public private(set) var failedIDs: Set<String> = []
    public private(set) var isConnecting = false
    public private(set) var disconnectingID: String?
    public private(set) var isSending = false
    public var pendingLink: WebLink?
    public var confirmingDisconnect: WebSession?
    public var isScanning = false {
        didSet { if !isScanning { scanMessage = nil } }
    }
    public private(set) var scanMessage: String?
    public internal(set) var isCameraAvailable = false
    public var error: CashlyError?
    public var linkError: CashlyError?
    public var connectError: CashlyError?
    public var isPro = false {
        didSet {
            guard isPro, !oldValue else { return }
            scheduleSend(after: .zero)
        }
    }
    public let endpoints: WebEndpoints
    @ObservationIgnored private let provider: any RepositoryProvider
    @ObservationIgnored private let store: any WebSessionStoring
    @ObservationIgnored private let bridge: WebBridge
    @ObservationIgnored private let preference: UserPreference
    @ObservationIgnored let now: @Sendable () -> Date
    @ObservationIgnored private var delivery: Task<Void, Never>?
    @ObservationIgnored private var pending: Task<Void, Never>?
    @ObservationIgnored private var expiry: Task<Void, Never>?
    @ObservationIgnored private var listener: Task<Void, Never>?
    @ObservationIgnored private var needsResend = false

    public init(
        provider: any RepositoryProvider, endpoints: WebEndpoints,
        store: any WebSessionStoring = KeychainWebSessionStore.standard,
        urlSession: URLSession = .shared, preference: UserPreference = .standard,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.provider = provider
        self.endpoints = endpoints
        self.store = store
        bridge = WebBridge(base: endpoints.bridge, session: urlSession)
        self.preference = preference
        self.now = now
        let saved = store.load()
        sessions = saved.filter { !$0.isExpired(at: now()) }
        if sessions.count != saved.count { persist() }
        scheduleExpiry()
        listen()
    }

    public convenience init?(
        provider: any RepositoryProvider, info: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) {
        guard let endpoints = WebEndpoints(info: info) else { return nil }
        self.init(provider: provider, endpoints: endpoints)
    }

    public var isSharing: Bool { !sessions.isEmpty }

    @discardableResult
    public func receive(_ url: URL) -> LinkOutcome {
        let host = endpoints.page.host() ?? ""
        guard WebLink.isLink(url, host: host) else { return .ignored }
        guard let link = try? WebLink(url, host: host) else {
            linkError = .invalidInput(Self.invalidLinkMessage)
            return .invalid
        }
        guard isPro else { return .needsPro }
        if sessions.contains(where: { $0.id == link.id }) {
            scheduleSend(after: .zero)
            return .alreadyConnected
        }
        pendingLink = link
        return .confirming
    }

    @discardableResult
    public func receive(scanned text: String) -> LinkOutcome {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
            let link = try? WebLink(url, host: endpoints.page.host() ?? "")
        else {
            scanMessage = Self.invalidLinkMessage
            return .invalid
        }
        guard isPro else { return .needsPro }
        isScanning = false
        if sessions.contains(where: { $0.id == link.id }) {
            scheduleSend(after: .zero)
            return .alreadyConnected
        }
        Task {
            try? await Task.sleep(for: Self.sheetHandoff)
            pendingLink = link
        }
        return .confirming
    }

    public func connect() async {
        guard let link = pendingLink, !isConnecting, isPro else { return }
        isConnecting = true
        defer { isConnecting = false }
        do {
            var session = try WebSession.pair(with: link, at: now())
            let plaintext = try await snapshot()
            try await bridge.put(
                session.seal(plaintext), id: session.id, ownerToken: session.ownerToken)
            session.lastSentAt = now()
            sessions.append(session)
            persist()
            scheduleExpiry()
            if pendingLink == link { pendingLink = nil }
        } catch is CancellationError {} catch {
            connectError = Self.pairingError(error)
        }
    }

    public func cancelLink() {
        pendingLink = nil
    }

    public func disconnect(_ session: WebSession) async {
        guard disconnectingID == nil else { return }
        disconnectingID = session.id
        defer { disconnectingID = nil }
        pending?.cancel()
        await delivery?.value
        do {
            if !session.isExpired(at: now()) {
                try await bridge.delete(id: session.id, ownerToken: session.ownerToken)
            }
            remove([session.id])
            if confirmingDisconnect?.id == session.id { confirmingDisconnect = nil }
        } catch is CancellationError {} catch {
            confirmingDisconnect = nil
            let failure = Self.cashlyError(error)
            Task {
                try? await Task.sleep(for: Self.sheetHandoff)
                self.error = failure
            }
        }
    }

    public func send() async {
        pruneExpired()
        guard isPro, !sessions.isEmpty else { return }
        if let delivery {
            needsResend = true
            return await delivery.value
        }
        let task = Task { await deliverUntilCurrent() }
        delivery = task
        await task.value
        delivery = nil
    }

    public func resume() {
        pruneExpired()
        scheduleSend(after: .zero)
    }

    public func scheduleSend(after delay: Duration = WebSharingModel.debounce) {
        guard !sessions.isEmpty else { return }
        pending?.cancel()
        pending = Task { [weak self] in
            if delay > .zero { try? await Task.sleep(for: delay) }
            guard !Task.isCancelled else { return }
            await self?.send()
        }
    }

    func pruneExpired() {
        let expired = sessions.filter { $0.isExpired(at: now()) }
        guard !expired.isEmpty else { return }
        remove(Set(expired.map(\.id)))
        for session in expired {
            Task { [bridge] in
                try? await bridge.delete(id: session.id, ownerToken: session.ownerToken)
            }
        }
    }

    private func deliverUntilCurrent() async {
        repeat {
            needsResend = false
            let targets = sessions.filter { !$0.isExpired(at: now()) && $0.id != disconnectingID }
            guard !targets.isEmpty else { return }
            isSending = true
            defer { isSending = false }
            let plaintext: Data
            do {
                plaintext = try await snapshot()
            } catch {
                failedIDs.formUnion(targets.map(\.id))
                return
            }
            for session in targets {
                guard !Task.isCancelled, disconnectingID != session.id else { continue }
                do {
                    try await bridge.put(
                        session.seal(plaintext), id: session.id, ownerToken: session.ownerToken)
                    markSent(session.id)
                } catch {
                    failedIDs.insert(session.id)
                }
            }
            persist()
        } while needsResend
    }

    private func snapshot() async throws -> Data {
        let users = try await provider.repositories(for: nil).users.users()
        let selected = preference.selectedUserID
        guard let user = users.first(where: { $0.id == selected }) ?? users.first else {
            throw CashlyError.missingRecord
        }
        return try await WebSnapshot.make(
            repositories: provider.repositories(for: user.id),
            context: WebSnapshot.Context(
                user: user, today: now(), currency: Money.currencyCode, locale: .app)
        ).encoded()
    }

    private func markSent(_ id: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].lastSentAt = now()
        failedIDs.remove(id)
    }

    private func remove(_ ids: Set<String>) {
        sessions.removeAll { ids.contains($0.id) }
        failedIDs.subtract(ids)
        persist()
        scheduleExpiry()
    }

    private func persist() {
        do {
            try store.save(sessions)
        } catch {
            self.error = .persistence(String(appLocalized: "Couldn't save the connection."))
        }
    }

    private func scheduleExpiry() {
        expiry?.cancel()
        guard let next = sessions.map(\.expiresAt).min() else { return }
        let delay = max(next.timeIntervalSince(now()), 0)
        expiry = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.pruneExpired()
        }
    }

    private func listen() {
        let changes = provider.changes
        listener = Task { [weak self] in
            for await _ in changes.changes() {
                self?.scheduleSend()
            }
        }
    }

    public static let debounce = Duration.seconds(2)
    static let sheetHandoff = Duration.milliseconds(500)
}
