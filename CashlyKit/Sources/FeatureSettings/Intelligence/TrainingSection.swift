import FeatureCore
import SwiftUI

struct TrainingSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(IntelligenceModel.self) private var intelligence

    var body: some View {
        Section {
            Button("Treinar modelos") { Task { await intelligence.train() } }
                .disabled(!intelligence.canTrain(with: session, finance: finance))
            Button("Apagar modelos", role: .destructive) { Task { await intelligence.clean() } }
                .disabled(session.user == nil || intelligence.isTraining)
            if intelligence.isTraining { ProgressView("Treinando") }
        } footer: {
            Text(
                "As estimativas usam os gastos mensais recentes. A categorização aprende com as descrições das suas transações. Todo o processamento fica neste aparelho."
            )
        }
    }
}
