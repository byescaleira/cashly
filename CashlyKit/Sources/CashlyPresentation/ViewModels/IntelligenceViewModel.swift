import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class IntelligenceViewModel {
    public private(set) var models: [IntelligenceModelInfo] = []
    public private(set) var isTraining = false
    public private(set) var datasetRevision = ""
    public var isStale: Bool { models.contains { $0.datasetRevision != datasetRevision } }
    public var error: CashlyError?
    @ObservationIgnored private let useCase: any IntelligenceUseCase
    @ObservationIgnored private var activeUserID: String?
    @ObservationIgnored private var modelsRevision = 0
    public init(useCase: any IntelligenceUseCase) { self.useCase = useCase }
    public func hasModel(_ kind: CashlyIntelligence) -> Bool {
        models.contains { $0.kind == kind && $0.datasetRevision == datasetRevision }
    }
    public func loadModels(user: User?, revision: String) async {
        modelsRevision += 1
        let request = modelsRevision
        activeUserID = user?.id
        datasetRevision = revision
        models = []
        error = nil
        guard let user else { return }
        do {
            let models = try await useCase.models(userID: user.id)
            try Task.checkCancellation()
            guard request == modelsRevision, user.id == activeUserID, revision == datasetRevision
            else { return }
            self.models = models
        } catch is CancellationError {} catch {
            if request == modelsRevision && !Task.isCancelled {
                self.error = .intelligence(error.localizedDescription)
            }
        }
    }
    public func train(user: User, dataset: TrainingDataset) async {
        guard !isTraining, user.id == activeUserID else { return }
        modelsRevision += 1
        isTraining = true
        error = nil
        defer { isTraining = false }
        do {
            let models = try await useCase.train(
                userID: user.id, transactions: dataset.transactions, tags: dataset.tags,
                revision: dataset.revision)
            try Task.checkCancellation()
            guard user.id == activeUserID else { return }
            self.models = models
        } catch is CancellationError {} catch {
            if user.id == activeUserID && !Task.isCancelled {
                self.error = .intelligence(error.localizedDescription)
            }
        }
    }
    public func clean(user: User) async {
        guard !isTraining, user.id == activeUserID else { return }
        modelsRevision += 1
        isTraining = true
        error = nil
        defer { isTraining = false }
        do {
            try await useCase.clean(userID: user.id)
            if user.id == activeUserID { models = [] }
        } catch is CancellationError {} catch {
            if user.id == activeUserID && !Task.isCancelled {
                self.error = .intelligence(error.localizedDescription)
            }
        }
    }
    public func predictExpenses(user: User, month: Int, categoryIDs: [String]) async -> Double {
        let revision = datasetRevision
        var total = 0.0
        for categoryID in categoryIDs {
            guard !Task.isCancelled, user.id == activeUserID, revision == datasetRevision else {
                return 0
            }
            let result = await predict(
                user: user, input: .budget(yearMonth: month, categoryID: categoryID))
            if case .tabularRegression(let amount) = result { total += amount }
        }
        return !Task.isCancelled && user.id == activeUserID && revision == datasetRevision
            ? total : 0
    }

    public func predict(user: User, input: CashlyPredictionInput) async -> CashlyPredictionResult {
        let revision = datasetRevision
        guard !revision.isEmpty, !isStale else { return .empty }
        do {
            let result = try await useCase.predict(
                userID: user.id, input: input, revision: revision)
            try Task.checkCancellation()
            return user.id == activeUserID && revision == datasetRevision ? result : .empty
        } catch { return .empty }
    }
}
