import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ScoreGuideScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    private let count = 5
    var onFinish: () -> Void = {}

    var body: some View {
        let isLast = index == count - 1
        GuideSheet(
            index: index, count: count, back: index > 0 ? { index -= 1 } : nil,
            primary: GuideAction(isLast ? "Got It" : "Continue") {
                if isLast {
                    onFinish()
                    dismiss()
                } else {
                    index += 1
                }
            }
        ) {
            switch index {
            case 0:
                GuidePage(
                    title: "Health Score",
                    message:
                        "A number from 200 to 1,000 that compares what you spent with what you planned for the period."
                ) {
                    CashlyAnimationView(.score)
                }
            case 1:
                GuidePage(
                    title: "The Ranges",
                    message:
                        "It stays at 1,000 up to 85% of the plan and drops gradually after that."
                ) {
                    CashlyAnimationView(.budgetPace)
                } content: {
                    ScoreScale()
                        .padding(.horizontal, .spaceL)
                }
            case 2:
                GuidePage(
                    title: "Each Range",
                    message: "The range depends on how much of the plan was spent."
                ) {
                    CashlyAnimationView(.budget)
                } content: {
                    GuideFeatureList {
                        ForEach(BudgetHealth.Level.allCases.reversed(), id: \.self) { level in
                            GuideFeature(
                                title: level.title, detail: Self.rule(for: level),
                                color: level.color)
                        }
                    }
                }
            case 3:
                GuidePage(
                    title: "Your Period Now",
                    message: "With the budgets and spending in the current filter."
                ) {
                    CashlyAnimationView(.score)
                } content: {
                    CurrentScore()
                }
            default:
                GuidePage(
                    title: "How to Raise It",
                    message:
                        "Small adjustments during the month make more difference than one cut at the end."
                ) {
                    CashlyAnimationView(.budget)
                } content: {
                    GuideFeatureList {
                        GuideFeature(
                            title: String(appLocalized: "Look at what's close to the limit"),
                            detail: String(appLocalized: "In Goals, these budgets show up first."))
                        GuideFeature(
                            title: String(appLocalized: "Plan realistic amounts"),
                            detail: String(
                                appLocalized:
                                    "A budget that goes over every month helps less than an adjusted one."
                            )
                        )
                        GuideFeature(
                            title: String(appLocalized: "Follow the daily amount"),
                            detail: String(
                                appLocalized:
                                    "The month summary shows how much you can spend until the end of the month."
                            )
                        )
                    }
                }
            }
        }
    }

    private static func rule(for level: BudgetHealth.Level) -> String {
        let limit = level.maximumUsage.formatted(
            .percent.precision(.fractionLength(0)).locale(.app))
        return switch level {
        case .healthy: String(appLocalized: "Spending up to \(limit) of plan.")
        case .overBudget, .atRisk: String(appLocalized: "Spending up to \(limit) of plan.")
        case .critical: String(appLocalized: "Above that; it reaches 200 at twice the plan.")
        }
    }
}

private struct CurrentScore: View {
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        let planned = finance.budgetsAmount
        let spent = finance.expensesAmount
        if planned > 0 {
            let keepFull = planned * BudgetHealth.fullScoreUsage - spent
            let keepHealthy = planned * BudgetHealth.Level.healthy.maximumUsage - spent
            GuideValueList([
                GuideValue(String(appLocalized: "Planned"), value: planned.formatted(.appCurrency)),
                GuideValue(
                    String(appLocalized: "Spent"),
                    value:
                        "\(spent.formatted(.appCurrency)) · \((spent / planned).formatted(.percent.precision(.fractionLength(0)).locale(.app)))"
                ),
            ])
            GuideFeatureList {
                if keepFull > 0 {
                    GuideFeature(
                        title: String(
                            appLocalized:
                                "\(keepFull.formatted(.appCurrency)) more and it stays at 1,000"),
                        color: .positive)
                }
                if keepHealthy > 0 {
                    GuideFeature(
                        title: String(
                            appLocalized:
                                "\(keepHealthy.formatted(.appCurrency)) more and it stays Healthy"),
                        color: .positive)
                } else {
                    GuideFeature(
                        title: String(appLocalized: "Spending is already over plan"),
                        detail:
                            String(
                                appLocalized:
                                    "The score rises again next period or with a bigger budget."),
                        color: .warning)
                }
            }
        } else {
            GuideFeatureList {
                GuideFeature(
                    title: String(appLocalized: "Set budgets in Goals"),
                    detail: String(
                        appLocalized: "Without a plan there's nothing to compare against."))
            }
        }
    }
}
