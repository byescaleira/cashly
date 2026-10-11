import CashlyAnalytics
import CashlyDomain
import CashlyMCP
import FeatureCore
import Foundation
import Network
import Observation

@MainActor @Observable
public final class MCPModel {
    public struct PendingImport: Identifiable, Sendable {
        public let id = UUID()
        public let preview: SpreadsheetPreview
        public let source: String
    }

    public struct ConnectionRequest: Identifiable, Sendable {
        public let id = UUID()
        public let client: MCPClient
    }

    public enum Prompt: Identifiable, Sendable {
        case connection(ConnectionRequest)
        case importing(PendingImport)

        public var id: UUID {
            switch self {
            case .connection(let request): request.id
            case .importing(let request): request.id
            }
        }
    }

    public enum State: Equatable {
        case off, starting, ready
        case failed(String)
    }

    public var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Key.enabled)
            isEnabled ? start() : stop()
        }
    }
    public var allowsLocalNetwork: Bool {
        didSet {
            defaults.set(allowsLocalNetwork, forKey: Key.localNetwork)
            restart()
        }
    }
    public private(set) var token: String
    public private(set) var trusted: [String]
    public private(set) var state = State.off
    public var pending: PendingImport?
    public var connection: ConnectionRequest?

    public var prompt: Prompt? {
        connection.map(Prompt.connection) ?? pending.map(Prompt.importing)
    }
    public let port = MCPHTTPServer.defaultPort
    @ObservationIgnored private let provider: any RepositoryProvider
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let serviceName: String
    @ObservationIgnored private var server: MCPHTTPServer?
    @ObservationIgnored private var imports: [UUID: CheckedContinuation<ImportOutcome, Never>] = [:]
    @ObservationIgnored private var approvals: [UUID: CheckedContinuation<Bool, Never>] = [:]

    public init(
        provider: any RepositoryProvider, defaults: UserDefaults = .standard,
        serviceName: String = "Cashly"
    ) {
        self.provider = provider
        self.defaults = defaults
        self.serviceName = serviceName
        token = defaults.string(forKey: Key.token) ?? Self.newToken()
        trusted = defaults.stringArray(forKey: Key.trusted) ?? []
        allowsLocalNetwork = defaults.bool(forKey: Key.localNetwork)
        isEnabled = defaults.bool(forKey: Key.enabled)
        defaults.set(token, forKey: Key.token)
        if isEnabled { start() }
    }

    public var host: String {
        allowsLocalNetwork ? (LocalAddress.current ?? "127.0.0.1") : "127.0.0.1"
    }

    public var command: String {
        "claude mcp add --transport http cashly http://\(host):\(port)/mcp --header \"Authorization: Bearer \(token)\""
    }

    public func regenerateToken() {
        token = Self.newToken()
        defaults.set(token, forKey: Key.token)
        revokeAll()
        restart()
    }

    public func revoke(_ key: String) {
        trusted.removeAll { $0 == key }
        defaults.set(trusted, forKey: Key.trusted)
    }

    public func revokeAll() {
        trusted = []
        defaults.set(trusted, forKey: Key.trusted)
    }

    public func answer(_ id: UUID, allow: Bool) {
        if allow, connection?.id == id, let client = connection?.client {
            let key = Self.key(client)
            if !trusted.contains(key) {
                trusted.append(key)
                defaults.set(trusted, forKey: Key.trusted)
            }
        }
        if connection?.id == id { connection = nil }
        approvals.removeValue(forKey: id)?.resume(returning: allow)
    }

    public func finish(_ id: UUID, imported: Int?) {
        if pending?.id == id { pending = nil }
        imports.removeValue(forKey: id)?.resume(
            returning: imported.map(ImportOutcome.imported) ?? .declined)
    }

    func authorize(_ client: MCPClient) async -> Bool {
        if trusted.contains(Self.key(client)) { return true }
        let request = ConnectionRequest(client: client)
        connection = request
        return await withCheckedContinuation { continuation in
            approvals[request.id] = continuation
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(120))
                self?.answer(request.id, allow: false)
            }
        }
    }

    func present(_ preview: SpreadsheetPreview, source: String) async -> ImportOutcome {
        let request = PendingImport(preview: preview, source: source)
        pending = request
        return await withCheckedContinuation { continuation in
            imports[request.id] = continuation
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(170))
                self?.imports.removeValue(forKey: request.id)?.resume(returning: .waiting)
            }
        }
    }

    static func key(_ client: MCPClient) -> String {
        "\(client.name) · \(client.address)"
    }

    private func restart() {
        guard isEnabled else { return }
        stop()
        start()
    }

    private func start() {
        guard server == nil else { return }
        let provider = provider
        let context = CashlyContext(
            workspace: { try await Self.workspace(provider) }, importer: Importer(model: self))
        let authorizer: MCPAuthorizer = { [weak self] client in
            guard let self else { return false }
            return await self.authorize(client)
        }
        do {
            let server = try MCPHTTPServer(
                server: CashlyTools.server(context, authorizer: authorizer), token: token,
                port: port,
                localNetwork: allowsLocalNetwork, serviceName: serviceName)
            state = .starting
            server.start { [weak self] state in
                Task { @MainActor in self?.update(state) }
            }
            self.server = server
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func stop() {
        server?.stop()
        server = nil
        state = .off
    }

    private func update(_ listener: NWListener.State) {
        switch listener {
        case .ready: state = .ready
        case .failed(let error): state = .failed(error.localizedDescription)
        case .cancelled: if state != .off { state = .off }
        default: break
        }
    }

    private nonisolated static func workspace(_ provider: any RepositoryProvider) async throws
        -> (Repositories, User)
    {
        let users = try await provider.repositories(for: nil).users.users()
        let selected = UserPreference.standard.selectedUserID
        guard let user = users.first(where: { $0.id == selected }) ?? users.first else {
            throw MCPToolError(
                "Nenhum perfil criado no Cashly ainda. Abra o app e conclua o início.")
        }
        return (provider.repositories(for: user.id), user)
    }

    private static func newToken() -> String {
        (0..<4).map { _ in UUID().uuidString.replacingOccurrences(of: "-", with: "") }.joined()
            .lowercased()
    }

    private enum Key {
        static let enabled = "cashly.mcp.enabled"
        static let token = "cashly.mcp.token"
        static let trusted = "cashly.mcp.trusted"
        static let localNetwork = "cashly.mcp.localNetwork"
    }
}

private struct Importer: TransactionImporting {
    weak var model: MCPModel?

    func requestImport(_ preview: SpreadsheetPreview, source: String) async -> ImportOutcome {
        guard let model else { return .declined }
        return await model.present(preview, source: source)
    }
}
