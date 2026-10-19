import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class AppUpdateModel {
    public static let interval: TimeInterval = 15 * 60
    public static let blockedInterval: TimeInterval = 60

    public private(set) var cache: AppReleaseCache
    public private(set) var dismissed: String?
    public private(set) var isChecking = false
    public var isShowingRecommendation = false
    public let installed: InstalledApp?
    public let enforces: Bool
    public let appStoreURL: URL?
    @ObservationIgnored private let store: AppReleaseStore
    @ObservationIgnored private let source: (any AppReleaseSource)?
    @ObservationIgnored private let platform: AppPlatform
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: @Sendable () -> Date
    @ObservationIgnored private var lastAttempt: Date?
    @ObservationIgnored private var hasShownRecommendation = false

    public init(
        store: AppReleaseStore = .shared, source: (any AppReleaseSource)? = nil,
        installed: InstalledApp? = .main, platform: AppPlatform = .current,
        enforces: Bool = AppReleaseStore.enforces, defaults: UserDefaults = .standard,
        appStoreURL: URL? = AppUpdateModel.storeURL(),
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.store = store
        self.source = source
        self.installed = installed
        self.platform = platform
        self.enforces = enforces
        self.defaults = defaults
        self.appStoreURL = appStoreURL
        self.now = now
        cache = store.read()
        dismissed = defaults.string(forKey: Key.dismissed).flatMap {
            $0 == Self.simulatedID ? nil : $0
        }
    }

    public var state: UpdateState { cache.state(for: installed, enforces: enforces) }

    public var remoteState: UpdateState { cache.remoteState(for: installed) }

    public var isRequired: Bool { state == .required }

    public var isSimulating: Bool { !enforces && cache.simulated != nil }

    public var isRecommendationDue: Bool {
        state == .recommended && dismissed != recommendationID
    }

    var recommendationID: String {
        isSimulating ? Self.simulatedID : cache.release?.recommendationID ?? ""
    }

    public func refresh(force: Bool = false) async {
        guard let source, !isChecking else { return }
        let date = now()
        let wait = isRequired ? Self.blockedInterval : Self.interval
        if !force, let last = [lastAttempt, cache.fetchedAt].compactMap(\.self).max(),
            date.timeIntervalSince(last) < wait
        {
            return
        }
        lastAttempt = date
        isChecking = true
        defer { isChecking = false }
        do {
            let release = try await source.fetch(platform: platform)
            cache.release = release
            cache.fetchedAt = date
            persist()
        } catch {
            return
        }
    }

    public func offerRecommendation() {
        guard isRecommendationDue else { return }
        isShowingRecommendation = true
    }

    public func recommendationAppeared() {
        hasShownRecommendation = true
    }

    public func dismissRecommendation() {
        isShowingRecommendation = false
        guard state == .recommended, hasShownRecommendation else { return }
        hasShownRecommendation = false
        dismissed = recommendationID
        if !isSimulating { defaults.set(dismissed, forKey: Key.dismissed) }
    }

    public func simulate(_ state: UpdateState?) {
        guard !enforces else { return }
        cache.simulated = state
        if state == .recommended { dismissed = nil }
        persist()
    }

    public nonisolated static func storeURL(
        info: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> URL? {
        let id = (info["CashlyAppStoreID"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        return URL(string: "https://apps.apple.com/app/id\(id ?? "6821986667")")
    }

    private static let simulatedID = "simulated"

    private func persist() {
        try? store.write(cache)
    }

    private enum Key {
        static let dismissed = "cashly.update.dismissedRecommendation"
    }
}
