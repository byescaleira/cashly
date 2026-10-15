import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct BudgetsWidgetView: View {
    let snapshot: WidgetSnapshot?
    let size: WidgetSize

    var body: some View {
        if let snapshot, !snapshot.budgets.isEmpty {
            let figures = MonthFigures(snapshot: snapshot, line: nil)
            VStack(alignment: .leading, spacing: .spaceM) {
                HStack {
                    WidgetTitle(snapshot: snapshot, ratio: figures.ratio)
                    Spacer(minLength: 0)
                    WidgetTag(
                        "\(snapshot.overBudgetCount)/\(snapshot.budgets.count)",
                        color: figures.color)
                }
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: .spaceM), GridItem(.flexible())],
                    spacing: .spaceS
                ) {
                    ForEach(snapshot.budgets.prefix(size == .large ? 10 : 4), id: \.id) {
                        BudgetCell(line: $0)
                    }
                }
                Spacer(minLength: 0)
            }
        } else if snapshot == nil {
            WidgetMessage.empty(size)
        } else {
            WidgetMessage.noBudgets(size)
        }
    }
}
