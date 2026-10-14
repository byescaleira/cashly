import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct BudgetsEmptySection: View {
    @Environment(GoalsModel.self) private var goals
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if goals.isShowingEmptyBudgets {
            Section {
                VStack(spacing: .spaceM) {
                    CashlyAnimationView(.goals).frame(maxWidth: 260)
                    Text("No budgets this month").font(.titleMedium)
                    Text(
                        "Set how much you want to spend in each category and follow the month's pace."
                    )
                    .font(.body)
                    .foregroundStyle(.secondary)
                    Button("Create Budget") { open(goals.newBudgetRoute, in: section) }
                        .primaryButton()
                        .padding(.top, .spaceS)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spaceM)
            }
        }
    }
}
