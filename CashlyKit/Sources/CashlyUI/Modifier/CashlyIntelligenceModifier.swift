import CashlyDomain
import CashlyPresentation
import Foundation
import SwiftUI

struct CashlyIntelligenceModifier: ViewModifier {
    @Environment(\.user) private var user
    @Environment(IntelligenceViewModel.self) private var intelligence
    @Binding var input: CashlyPredictionInput
    @Binding var result: CashlyPredictionResult
    let model: CashlyIntelligence
    let isActive: Bool
    init(
        model: CashlyIntelligence, isActive: Bool = true, input: Binding<CashlyPredictionInput>,
        result: Binding<CashlyPredictionResult>
    ) {
        self.model = model
        self.isActive = isActive
        self._input = input
        self._result = result
    }
    private struct Request: Hashable {
        let userID: String?
        let input: CashlyPredictionInput
        let isActive: Bool
        let revision: String
        let modelDates: [Date]
    }
    func body(content: Content) -> some View {
        content.task(
            id: Request(
                userID: user?.id, input: input, isActive: isActive,
                revision: intelligence.datasetRevision,
                modelDates: intelligence.models.map(\.updateDate))
        ) {
            guard let user, isActive, input != .empty, intelligence.hasModel(model) else {
                result = .empty
                return
            }
            let request = input
            do {
                try await Task.sleep(for: .milliseconds(350))
                let prediction = await intelligence.predict(user: user, input: request)
                try Task.checkCancellation()
                result = prediction
                if model != .categoryName { input = .empty }
            } catch is CancellationError {} catch { result = .empty }
        }
    }
}
