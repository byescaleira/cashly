import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct HistorySection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let history = insights.history {
            Section {
                VStack(spacing: .spaceS) {
                    FigureBlock(
                        caption: history.difference <= 0
                            ? "Você gastou a menos que o normal"
                            : "Você gastou a mais que o normal",
                        amount: abs(history.difference),
                        color: history.difference <= 0 ? .positive : .negative,
                        detail: history.months == 1
                            ? "Comparado ao mês passado, até o dia \(history.day)."
                            : "Comparado à média dos últimos \(history.months) meses, até o dia \(history.day)."
                    )
                    InsightBars(bars: history.bars)
                }
            } header: {
                Text("Comparado aos outros meses").sectionTitle()
            }
        }
    }
}

struct UnusualSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        let unusual = insights.unusual
        if !unusual.isEmpty {
            Section {
                ForEach(unusual) { item in
                    HStack(alignment: .center, spacing: .spaceM) {
                        VStack(alignment: .leading, spacing: .spaceHairline) {
                            Text(item.name).font(.headline)
                            Text(item.reference)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .trailing, spacing: .space2XS) {
                            Text(item.current.formatted(.appCurrency))
                                .font(.headline)
                                .amountLine()
                            Chip(item.badge, color: .warning)
                        }
                    }
                }
            } header: {
                Text("Fora do padrão").sectionTitle()
            } footer: {
                Text("Gasto até hoje comparado ao que costuma sair até este dia do mês.")
            }
        }
    }
}
