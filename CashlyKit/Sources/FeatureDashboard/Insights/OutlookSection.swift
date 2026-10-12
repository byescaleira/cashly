import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct OutlookSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let outlook = insights.outlook {
            let isOver = (outlook.gap ?? 0) > 0
            Section {
                VStack(spacing: 12) {
                    InsightHeadline(
                        caption: "O mês deve fechar em", value: outlook.projected,
                        color: isOver ? .negative : .primary)
                    if let gap = outlook.gap {
                        InsightChip(
                            text: gap > 0
                                ? "\(gap.formatted(.appCurrency)) acima do planejado"
                                : "\((-gap).formatted(.appCurrency)) abaixo do planejado",
                            color: gap > 0 ? .negative : .positive)
                    }
                    OutlookBar(outlook: outlook)
                        .padding(.top, 8)
                }
                OutlookRow(
                    title: "Já gasto", value: outlook.spent, marker: .solid)
                OutlookRow(
                    title: "Ainda deve sair", value: outlook.remaining, marker: .faded)
                if let budgeted = outlook.budgeted {
                    OutlookRow(title: "Planejado", value: budgeted, marker: .line)
                }
                if let daily = outlook.daily, let days = outlook.daysLeft {
                    LabeledContent {
                        Text("\(daily.formatted(.appCurrency)) por dia")
                            .fontWeight(.semibold)
                            .foregroundStyle(daily > 0 ? Color.positive : .negative)
                    } label: {
                        Text("Dá para gastar")
                        Text("nos próximos \(days) dias, sem passar do planejado")
                    }
                }
            } header: {
                Text("Previsão do mês").sectionTitle()
            } footer: {
                Text(
                    outlook.isUncertain
                        ? "Ainda são poucos dias e pouco histórico; a previsão melhora com o tempo."
                        : "Soma o que já saiu, as contas agendadas e o que você costuma gastar até o fim do mês."
                )
            }
        }
    }
}

private enum OutlookMarker {
    case solid, faded, line
}

private struct OutlookRow: View {
    @Environment(\.appTint) private var appTint
    let title: LocalizedStringKey
    let value: Double
    let marker: OutlookMarker

    var body: some View {
        LabeledContent {
            Text(value.formatted(.appCurrency)).amountLine()
        } label: {
            Label {
                Text(title)
            } icon: {
                switch marker {
                case .solid: Capsule().fill(appTint).frame(width: 14, height: 8)
                case .faded: Capsule().fill(appTint.opacity(0.35)).frame(width: 14, height: 8)
                case .line: Capsule().fill(Color.primary).frame(width: 3, height: 14)
                }
            }
        }
    }
}

private struct OutlookBar: View {
    @Environment(\.appTint) private var appTint
    let outlook: InsightsModel.Outlook

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let spent = width * min(outlook.spent / outlook.scale, 1)
            let projected = width * min(outlook.projected / outlook.scale, 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule().fill(appTint.opacity(0.35)).frame(width: projected)
                Capsule().fill(appTint).frame(width: max(spent, 14))
                if let budgeted = outlook.budgeted {
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: 3, height: 26)
                        .offset(x: min(width * budgeted / outlook.scale, width) - 1.5)
                }
            }
        }
        .frame(height: 14)
        .animation(.smooth, value: outlook)
        .accessibilityHidden(true)
    }
}
