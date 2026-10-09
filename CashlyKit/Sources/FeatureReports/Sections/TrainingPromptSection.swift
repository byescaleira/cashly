import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TrainingPromptSection: View {
    @Environment(ReportsModel.self) private var reports

    var body: some View {
        if reports.suggestsTraining {
            Section {
                VStack(spacing: 12) {
                    Text(
                        "Treine os modelos para ver a estimativa de gastos do mês. Tudo é calculado neste aparelho, com o seu histórico."
                    )
                    .font(.callout)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    Button("Treinar modelos") { Task { await reports.train() } }
                        .prominentButton()
                        .disabled(reports.isTraining)
                    if reports.isTraining { ProgressView() }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } header: {
                Text("Previsão de gastos").sectionTitle()
            }
        }
    }
}
