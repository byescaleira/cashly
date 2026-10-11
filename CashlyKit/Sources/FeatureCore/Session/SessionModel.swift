import CashlyDomain
import Observation

@MainActor @Observable
public final class SessionModel {
    public private(set) var users: [User] = []
    public private(set) var user: User?
    public private(set) var generation = 0
    public private(set) var hasLoadedUsers = false
    public var filter = TransactionFilter()
    public var error: CashlyError?
    @ObservationIgnored private let provider: any RepositoryProvider
    @ObservationIgnored private let preference: UserPreference
    @ObservationIgnored private var hasResolvedPreference = false
    @ObservationIgnored private var selectionRequest = 0

    public init(provider: any RepositoryProvider, preference: UserPreference = .standard) {
        self.provider = provider
        self.preference = preference
    }

    public var repositories: Repositories { provider.repositories(for: user?.id) }

    public var query: TransactionQuery { filter.query }

    public var loadKey: SessionLoadKey {
        SessionLoadKey(userID: user?.id, query: query, generation: generation)
    }

    public func start() async {
        await refreshUsers()
        for await change in provider.changes.changes() {
            guard !Task.isCancelled else { return }
            guard change.userID == nil || change.userID == user?.id else { continue }
            do { try await Task.sleep(for: .milliseconds(120)) } catch { return }
            await refreshUsers()
            generation += 1
        }
    }

    public func reload() {
        generation += 1
    }

    public func refreshUsers() async {
        do {
            let directory = try await provider.repositories(for: nil).users.users()
            try Task.checkCancellation()
            var selectedID = user?.id
            if !hasResolvedPreference {
                hasResolvedPreference = true
                selectedID = preference.selectedUserID
            }
            users = directory
            user = directory.first { $0.id == selectedID } ?? directory.first
            hasLoadedUsers = true
        } catch is CancellationError {} catch {
            self.error = error as? CashlyError ?? .onFetch
        }
    }

    public var otherUsers: [User] { users.filter { $0.id != user?.id } }
    public var needsOnboarding: Bool { hasLoadedUsers && users.isEmpty }
    public func isReady(_ finance: FinanceModel) -> Bool {
        hasLoadedUsers && (users.isEmpty || finance.hasLoaded)
    }

    public var userSelection: User? {
        get { user }
        set {
            guard let newValue else { return }
            Task { await selectUser(newValue) }
        }
    }

    public func selectUser(_ user: User) async {
        await selectUser(id: user.id)
    }

    public func selectUser(id: String) async {
        selectionRequest += 1
        let request = selectionRequest
        guard let value = try? await provider.repositories(for: nil).users.user(id: id) else {
            error = .missingRecord
            return
        }
        guard request == selectionRequest else { return }
        hasResolvedPreference = true
        if !users.contains(where: { $0.id == value.id }) { await refreshUsers() }
        user = value
        filter = filter.keepingPeriod
        preference.save(id)
        generation += 1
    }
}
