import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct ForecastSection: View {
    @Environment(ReportsModel.self) private var reports

    var body: some View {
        if reports.showsForecast {
            Section {
                VStack(spacing: 16) {
                    Text(
                        "Estimativa dos gastos do mês, feita no aparelho a partir do seu histórico."
                    )
                    .font(.callout)
                    .foregroundStyle(Color.secondary)
                    Text(reports.forecast.formatted(.appCurrency))
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.primary)
                        .amountLine()
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            } header: {
                Text("Previsão de gastos").sectionTitle()
            }
        }
    }
}
