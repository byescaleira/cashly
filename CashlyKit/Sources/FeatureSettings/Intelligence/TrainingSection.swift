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
                IconRow("Treinar modelos", symbol: "brain", color: appTint)
            }
            .disabled(!intelligence.canTrain(with: session, finance: finance))
            Button(role: .destructive) {
                Task { await intelligence.clean() }
            } label: {
                IconRow(
                    "Apagar modelos", symbol: "trash", color: .negative, titleColor: .negative)
            }
            .disabled(session.user == nil || intelligence.isTraining)
            if intelligence.isTraining { ProgressView("Treinando") }
        } footer: {
            Text(
                "As estimativas usam os gastos mensais recentes. A categorização aprende com as descrições das suas transações. Todo o processamento fica neste aparelho."
            )
        }
    }
}
