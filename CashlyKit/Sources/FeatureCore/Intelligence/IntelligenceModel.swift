import CashlyDomain
import Observation

@MainActor @Observable
public final class IntelligenceModel {
    public private(set) var models: [IntelligenceModelInfo] = []
    public private(set) var isTraining = false
    public private(set) var datasetRevision = ""
    public var error: CashlyError?
    @ObservationIgnored private let service: any IntelligenceService
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let flags: FeatureFlags?
    @ObservationIgnored private var activeUserID: String?
    @ObservationIgnored private var request = 0

    public init(
        service: any IntelligenceService, session: SessionModel, flags: FeatureFlags? = nil
    ) {
        self.service = service
        self.session = session
        self.flags = flags
    }

    public var isEnabled: Bool {
        flags?.isOn(.intelligence) ?? FeatureFlag.intelligence.defaultValue
    }

    public var isStale: Bool { models.contains { $0.datasetRevision != datasetRevision } }

    public func hasModel(_ kind: CashlyIntelligence) -> Bool {
        isEnabled && models.contains { $0.kind == kind && $0.datasetRevision == datasetRevision }
    }

    public func loadModels(revision: String) async {
        request += 1
        let current = request
        let userID = session.user?.id
        activeUserID = userID
        datasetRevision = revision
        models = []
        error = nil
        guard let userID else { return }
        do {
            let models = try await service.models(userID: userID)
            try Task.checkCancellation()
            guard current == request, userID == activeUserID, revision == datasetRevision
            else { return }
            self.models = models
        } catch is CancellationError {} catch {
            if current == request && !Task.isCancelled {
                self.error = .intelligence(error.localizedDescription)
            }
        }
    }

    public func train() async {
        await runTraining { userID in
            let dataset = try await self.session.repositories.dashboard.trainingData()
            let models = try await self.service.train(
                userID: userID, transactions: dataset.transactions, tags: dataset.tags,
                revision: dataset.revision)
            if userID == self.activeUserID { self.models = models }
        }
    }

    public func clean() async {
        await runTraining { userID in
            try await self.service.clean(userID: userID)
            if userID == self.activeUserID { self.models = [] }
        }
    }

    public func predict(_ input: CashlyPredictionInput) async -> CashlyPredictionResult {
        let revision = datasetRevision
        guard isEnabled, let userID = activeUserID, !revision.isEmpty, !isStale else {
            return .empty
        }
        do {
            let result = try await service.predict(userID: userID, input: input, revision: revision)
            try Task.checkCancellation()
            return userID == activeUserID && revision == datasetRevision ? result : .empty
        } catch { return .empty }
    }

    public func predictExpenses(month: YearMonth, categoryIDs: [String]) async -> Double {
        let revision = datasetRevision
        let userID = activeUserID
        var total = 0.0
        for categoryID in categoryIDs {
            guard !Task.isCancelled, userID == activeUserID, revision == datasetRevision else {
                return 0
            }
            let result = await predict(.budget(month: month, categoryID: categoryID))
            if case .tabularRegression(let amount) = result { total += amount }
        }
        return !Task.isCancelled && userID == activeUserID && revision == datasetRevision
            ? total : 0
    }

    private func runTraining(_ work: (String) async throws -> Void) async {
        guard !isTraining, let userID = activeUserID, userID == session.user?.id else { return }
        request += 1
        isTraining = true
        error = nil
        defer { isTraining = false }
        do {
            try await work(userID)
        } catch is CancellationError {} catch {
            self.error = .intelligence(error.localizedDescription)
        }
    }
}
