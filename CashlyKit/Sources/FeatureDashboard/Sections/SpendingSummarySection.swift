import FeatureCore
import SwiftUI

struct SpendingSummarySection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        if !session.users.isEmpty {
            PeriodSummaryHeader(
                amount: finance.expensesAmount,
                items: finance.warningCategories.map {
                    .init(
                        id: $0.id, name: $0.name, icon: $0.icon,
                        color: finance.categoryUsage(category: $0).stage.color)
                },
                badge: (finance.usage.stage.title, finance.usage.stage.color))
        }
    }
}
