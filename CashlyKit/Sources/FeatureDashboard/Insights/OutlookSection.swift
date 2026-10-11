import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct OutlookSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let outlook = insights.outlook {
            Section {
                VStack(spacing: 8) {
                    InsightHeadline(
                        caption: "No ritmo atual, o mês fecha em", value: outlook.projected,
                        color: (outlook.gap ?? 0) > 0 ? .negative : .primary)
                    if let gap = outlook.gap {
                        InsightChip(
                            text: gap > 0
                                ? "\(gap.formatted(.appCurrency)) acima do planejado"
                                : "\((-gap).formatted(.appCurrency)) abaixo do planejado",
                            color: gap > 0 ? .negative : .positive)
                    }
                }
                LabeledContent("Gasto até hoje", value: outlook.spent.formatted(.appCurrency))
                if let budgeted = outlook.budgeted {
                    LabeledContent("Planejado", value: budgeted.formatted(.appCurrency))
                }
                if let daily = outlook.daily, let days = outlook.daysLeft {
                    LabeledContent {
                        Text("\(daily.formatted(.appCurrency)) por dia")
                            .fontWeight(.semibold)
                            .foregroundStyle(daily > 0 ? Color.positive : .negative)
                    } label: {
                        Text("Dá para gastar")
                        Text("nos próximos \(days) dias")
                    }
                }
            } header: {
                Text("Este mês").sectionTitle()
            } footer: {
                if outlook.isUncertain {
                    Text("Ainda são poucos dias no mês; a estimativa melhora com o tempo.")
                }
            }
        }
    }
}
