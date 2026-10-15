import CashlyDesignSystem
import CashlyGame
import FeatureCore
import SwiftUI

struct AchievementDetailScreen: View {
    @Environment(JourneyModel.self) private var journey
    let state: AchievementState

    var body: some View {
        let detail = journey.achievementDetail(state)
        GuideSheet(
            index: 0, count: 1,
            primary: GuideAction("Done") { journey.closeAchievement() },
            secondary: detail.action.map { action in
                GuideAction(action.title) { journey.follow(action) }
            }
        ) {
            GuidePage(verbatim: detail.title, message: detail.message) {
                AchievementMedallion(state: state)
            } content: {
                AchievementDetailRows(detail: detail, color: state.achievement.tier.color)
            }
        }
    }
}

private struct AchievementDetailRows: View {
    let detail: AchievementDetail
    let color: Color

    var body: some View {
        VStack(spacing: .spaceM) {
            GuideValueList(
                detail.rows.map {
                    GuideValue($0.label, value: $0.value, color: $0.tone.color(tier: color))
                })
            if let tip = detail.tip {
                GuideFeatureList {
                    GuideFeature(title: detail.tipTitle, detail: tip)
                }
            }
        }
    }
}

extension AchievementDetail.Tone {
    fileprivate func color(tier: Color) -> Color {
        switch self {
        case .plain: .primary
        case .positive: .positive
        case .tier: tier
        }
    }
}

extension AchievementAction {
    fileprivate var title: LocalizedStringKey {
        switch self {
        case .open(.addCategory): "Add Category"
        case .open(.addBudget): "New Budget"
        case .open(.addTag): "Add Tag"
        case .open(.budgets): "Open Budgets"
        case .open: "Add Transaction"
        case .guide(.importSpreadsheet): "Import a Spreadsheet"
        case .guide: "Read the Guide"
        case .challenge: "Choose a Challenge"
        }
    }
}
