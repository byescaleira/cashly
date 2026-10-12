import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TrainingSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            Button {
                Task { await intelligence.train() }
            } label: {
                IconRow("Train Models", symbol: "brain", color: appTint)
            }
            .disabled(!intelligence.canTrain(with: session, finance: finance))
            Button(role: .destructive) {
                Task { await intelligence.clean() }
            } label: {
                IconRow(
                    "Delete Models", symbol: "trash", color: .negative, titleColor: .negative)
            }
            .disabled(session.user == nil || intelligence.isTraining)
            if intelligence.isTraining { ProgressView("Training") }
        } footer: {
            Text(
                "Estimates use your recent monthly spending. Categorization learns from your transaction descriptions. All processing stays on this device."
            )
        }
    }
}
