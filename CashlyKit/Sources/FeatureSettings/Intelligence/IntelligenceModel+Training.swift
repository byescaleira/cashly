import CashlyDomain
import FeatureCore

extension IntelligenceModel {
    func canTrain(with session: SessionModel, finance: FinanceModel) -> Bool {
        session.user != nil && finance.totalTransactionCount >= 2 && finance.pendingReferences == 0
            && !isTraining
    }

    func info(for kind: CashlyIntelligence) -> IntelligenceModelInfo? {
        models.first { $0.kind == kind }
    }
}
