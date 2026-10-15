import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

public enum ChallengeCost: Equatable, Sendable {
    case free
    case reroll(left: Int)
    case locked
}

extension JourneyModel {
    public var challengeThemes: [Challenge.Theme] { Challenge.Theme.allCases }

    public func kinds(in theme: Challenge.Theme) -> [Challenge.Kind] {
        Challenge.Kind.kinds(in: theme)
    }

    public func blocker(for kind: Challenge.Kind) -> ChallengeHints.Blocker? {
        progress?.challengeHints.blocker(for: kind)
    }

    public var challengeSuggestions: [Challenge.Kind] {
        let calendar = CashlyCalendar.current
        let seed = calendar.component(.weekOfYear, from: now())
        let open = Challenge.Kind.allCases.filter { blocker(for: $0) == nil }
        return Challenge.Difficulty.allCases.compactMap { difficulty in
            let kinds = open.filter { $0.difficulty == difficulty }
            return kinds.isEmpty ? nil : kinds[seed % kinds.count]
        }
    }

    public var recentChallenges: [ChallengeState] { progress?.recentChallenges ?? [] }

    public var challengeCost: ChallengeCost {
        guard let progress else { return .locked }
        if progress.challengeStartsThisMonth == 0 { return .free }
        return progress.rerolls > 0 ? .reroll(left: progress.rerolls) : .locked
    }

    public var canStartDraft: Bool {
        draft.challenge != nil && blocker(for: draft.kind) == nil && challengeCost != .locked
    }

    public func chooseChallenge(_ kind: Challenge.Kind) {
        chooseChallenge()
        select(kind)
    }

    public func select(_ kind: Challenge.Kind) {
        draft.kind = kind
        if kind == .cutBiggest {
            draft.categoryID = progress?.challengeHints.biggestLastMonth
        } else if !categories.contains(where: { $0.id == draft.categoryID }) {
            draft.categoryID = defaultCategoryID
        }
        if kind.needsLimit { draft.limit = suggestedLimit ?? 0 }
        challengePath = [kind]
    }

    public var draftCategoryID: String? {
        get { draft.categoryID }
        set {
            draft.categoryID = newValue
            if draft.kind.needsLimit { draft.limit = suggestedLimit ?? 0 }
        }
    }

    public var suggestedLimit: Double? {
        guard let id = draft.categoryID,
            let average = progress?.challengeHints.monthlyAverage[id], average > 0
        else { return nil }
        let target = average * JourneyModel.suggestedShare / 100
        let step = JourneyModel.suggestionStep
        let rounded = target >= step ? target / step * step : target
        return Money(minorUnits: max(rounded, 1)).doubleValue
    }

    public func useSuggestedLimit() {
        if let suggestedLimit { draft.limit = suggestedLimit }
    }

    public var draftPeriod: DateInterval {
        draft.kind.period(startingAt: now(), calendar: CashlyCalendar.current)
    }

    var defaultCategoryID: String? {
        let busiest = progress?.challengeHints.busiestCategory
        return categories.first { $0.id == busiest }?.id ?? categories.first?.id
    }

    var draftCategoryName: String {
        categories.first { $0.id == draft.categoryID }?.name ?? ""
    }

    static let suggestedShare: Int64 = 90
    static let suggestionStep: Int64 = 1_000
}
