import CashlyDesignSystem
import CashlyDomain
import CashlyGame
import FeatureCore
import SwiftUI

extension Achievement {
    var detail: String { detail(guides: Guide.free.count) }

    var symbol: String {
        switch group {
        case .firstSteps: firstStepSymbol
        case .consistency: "flame.fill"
        case .inTheBlue: self == .perfectMonth ? "star.fill" : "checkmark.seal.fill"
        case .volume: "list.bullet"
        case .organization: organizationSymbol
        case .together: "person.2.fill"
        case .challenges: "flag.checkered"
        case .levels: "arrow.up.circle.fill"
        case .pro: "crown.fill"
        case .secret: "sparkles"
        }
    }

    private var firstStepSymbol: String {
        switch self {
        case .firstCategory: "square.grid.2x2.fill"
        case .firstBudget: "chart.pie.fill"
        case .firstTag: "tag.fill"
        case .firstSplit: "person.2.fill"
        case .firstBackup: "externaldrive.fill"
        default: "plus.circle.fill"
        }
    }

    private var organizationSymbol: String {
        switch self {
        case .tagsInUse5: "tag.fill"
        case .fullyBudgeted: "checklist"
        default: "book.fill"
        }
    }
}

extension Achievement.Tier {
    var title: String {
        switch self {
        case .bronze: String(appLocalized: "Bronze")
        case .silver: String(appLocalized: "Silver")
        case .gold: String(appLocalized: "Gold")
        }
    }

    var color: Color {
        switch self {
        case .bronze: .retroBrown
        case .silver: .retroDenim
        case .gold: .retroMustard
        }
    }
}

extension AchievementState {
    var isHidden: Bool { achievement.isSecret && !isUnlocked }
    var title: String { isHidden ? String(appLocalized: "Secret") : achievement.title }
    var detail: String {
        isHidden
            ? String(appLocalized: "Secret achievements show what they ask once you find them.")
            : achievement.detail
    }
    var symbol: String { isHidden ? "questionmark" : achievement.symbol }
}
