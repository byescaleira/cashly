import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct ForecastSection: View {
    @Environment(DashboardModel.self) private var dashboard

    var body: some View {
        if dashboard.showsForecast {
            Section {
                VStack(spacing: 16) {
                    Text(
                        "Estimativa dos gastos do mês, feita no aparelho a partir do seu histórico."
                    )
                    .font(.callout)
                    .foregroundStyle(Color.secondary)
                    Text(dashboard.forecast.formatted(.brl))
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.primary)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            } header: {
                Text("Previsão de gastos").sectionTitle()
            }
        }
    }
}
