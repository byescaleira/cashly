import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

public struct AchievementDetail: Equatable {
    public enum Tone: Equatable {
        case plain, positive, tier
    }

    public struct Row: Equatable {
        public let label: String
        public let value: String
        public let tone: Tone
    }

    public let title: String
    public let message: String
    public let rows: [Row]
    public let tipTitle: String
    public let tip: String?
    public let action: AchievementAction?
}

extension JourneyModel {
    public func state(of achievement: Achievement) -> AchievementState? {
        progress?.achievements.first { $0.achievement == achievement }
    }

    public func reward(for celebration: Celebration) -> String? {
        guard case .achievement(let achievement) = celebration, achievement.xp > 0 else {
            return nil
        }
        return String(appLocalized: "+\(achievement.xp) XP")
    }

    public func achievementDetail(_ state: AchievementState) -> AchievementDetail {
        AchievementDetail(
            title: state.title, message: state.detail, rows: rows(of: state),
            tipTitle: state.isHidden
                ? String(appLocalized: "Clue") : String(appLocalized: "How to Get It"),
            tip: tip(for: state), action: action(for: state))
    }

    public func unlockCaption(of state: AchievementState) -> String? {
        guard state.isUnlocked, let date = unlockDates[state.achievement] else { return nil }
        return date.formatted(Date.FormatStyle(date: .numeric, time: .omitted, locale: .app))
    }

    public func tip(for state: AchievementState) -> String? {
        guard !state.isUnlocked else { return nil }
        let achievement = state.achievement
        switch achievement.group {
        case .challenges where progress?.challenge != nil:
            return String(appLocalized: "Finish your current challenge before it ends to count it.")
        case .levels:
            let missing = max(GameLevel.threshold(achievement.target) - (progress?.xp ?? 0), 0)
            let xp = missing.formatted(.number.locale(.app))
            return String(appLocalized: "\(xp) XP to go.") + " " + achievement.tip
        default:
            return achievement.tip
        }
    }

    public func action(for state: AchievementState) -> AchievementAction? {
        guard !state.isUnlocked, let action = state.achievement.action else { return nil }
        if action == .pro, isPro { return nil }
        if action == .challenge, progress?.challenge != nil || progress?.canStartChallenge == false
        {
            return nil
        }
        return action
    }

    public func nextInSeries(after achievement: Achievement) -> AchievementState? {
        guard Self.seriesGroups.contains(achievement.group), achievement != .perfectMonth else {
            return nil
        }
        return progress?.achievements
            .filter {
                $0.achievement.group == achievement.group && $0.achievement != .perfectMonth
                    && $0.achievement.target > achievement.target && !$0.isUnlocked
            }
            .min { $0.achievement.target < $1.achievement.target }
    }

    public func follow(_ action: AchievementAction) {
        pendingAction = action
        selected = nil
    }

    public func closeAchievement() {
        selected = nil
    }

    var offersShopAfterCelebration: Bool { celebrations.count == 1 }

    func browseShopAfterCelebration() {
        pendingAction = .open(.shop)
    }

    public func performPendingAction(
        pro: ProAccess, open: (Route) -> Void, guide: (Guide) -> Void
    ) {
        guard let action = pendingAction else { return }
        pendingAction = nil
        switch action {
        case .open(let route): open(route)
        case .guide(let item): guide(item)
        case .challenge: chooseChallenge()
        case .pro: pro.present()
        }
    }

    func stampUnlocks(_ fresh: [Achievement], unlocked: [Achievement], userID: String) {
        let key = AchievementUnlocks.key(for: userID)
        let stored = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        let kept = Set(unlocked.map(\.rawValue))
        var dates = stored.filter { kept.contains($0.key) }
        for achievement in fresh {
            dates[achievement.rawValue] = now().timeIntervalSince1970
        }
        defaults.set(dates, forKey: key)
        unlockDates = AchievementUnlocks.dates(dates)
    }

    private func rows(of state: AchievementState) -> [AchievementDetail.Row] {
        guard !state.isHidden else {
            return [
                AchievementDetail.Row(
                    label: String(appLocalized: "Status"), value: String(appLocalized: "Secret"),
                    tone: .plain)
            ]
        }
        let achievement = state.achievement
        let reward = AchievementDetail.Row(
            label: String(appLocalized: "Reward"),
            value: achievement.xp > 0
                ? String(appLocalized: "\(achievement.tier.title) · \(achievement.xp) XP")
                : achievement.tier.title,
            tone: .tier)
        guard state.isUnlocked else { return [progressRow(of: state), reward] }
        var rows = [unlockRow(of: state), reward]
        if let next = nextInSeries(after: achievement) {
            rows.append(
                AchievementDetail.Row(
                    label: String(appLocalized: "Next"),
                    value: next.achievement.title + " · " + valueCaption(of: next), tone: .plain))
        }
        return rows
    }

    private func progressRow(of state: AchievementState) -> AchievementDetail.Row {
        guard state.achievement.target > 1 else {
            return AchievementDetail.Row(
                label: String(appLocalized: "Status"), value: String(appLocalized: "Locked"),
                tone: .plain)
        }
        return AchievementDetail.Row(
            label: String(appLocalized: "Progress"), value: valueCaption(of: state), tone: .plain)
    }

    private func unlockRow(of state: AchievementState) -> AchievementDetail.Row {
        guard let date = unlockCaption(of: state) else {
            return AchievementDetail.Row(
                label: String(appLocalized: "Status"), value: String(appLocalized: "Unlocked"),
                tone: .positive)
        }
        return AchievementDetail.Row(
            label: String(appLocalized: "Unlocked"), value: date, tone: .positive)
    }

    private static let seriesGroups: Set<Achievement.Group> = [
        .consistency, .inTheBlue, .volume, .together, .challenges, .levels, .pro,
    ]
}

extension AchievementState {
    public var showsProgressBar: Bool {
        !isUnlocked && !achievement.isSecret && achievement.target > 1
    }
}
