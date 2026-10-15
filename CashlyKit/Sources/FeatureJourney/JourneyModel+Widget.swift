import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation
import WidgetKit

extension JourneyModel {
    public static func publish(
        session: SessionModel, status: JourneySnapshot.Status,
        store: JourneySnapshotStore? = .shared
    ) async {
        let model = JourneyModel(session: session, journeyStore: store)
        if session.user != nil {
            guard let progress = await model.compute() else { return }
            model.progress = progress
        }
        await model.publish(status: status)
    }

    public func widgetSnapshot(status: JourneySnapshot.Status) -> JourneySnapshot? {
        guard let progress, let userID = session.user?.id else { return nil }
        let level = progress.level
        let streak = progress.streak
        return JourneySnapshot(
            userID: userID, status: status, currencyCode: Money.currencyCode,
            level: JourneySnapshot.Level(
                number: level.number, title: level.title, xpIntoLevel: level.xpIntoLevel,
                xpForNextLevel: level.xpForNextLevel, totalXP: progress.xp),
            streak: JourneySnapshot.Streak(
                current: streak.current, best: streak.best, freezes: streak.freezes,
                isTodayTracked: streak.isTodayTracked,
                day: CashlyCalendar.current.startOfDay(for: now())),
            missions: progress.missions.map {
                JourneySnapshot.Mission(
                    id: $0.kind.rawValue, title: $0.kind.title, symbol: $0.kind.symbol,
                    value: min($0.value, $0.kind.target), target: $0.kind.target, xp: Mission.xp)
            },
            challenge: progress.challenge.map(widgetChallenge),
            lastChallenge: progress.recentChallenges.first.map(widgetChallenge),
            nextAchievement: nextAchievements.first.map {
                JourneySnapshot.Achievement(
                    title: $0.achievement.title, symbol: $0.achievement.symbol,
                    value: min($0.value, $0.achievement.target), target: $0.achievement.target,
                    xp: $0.achievement.xp)
            })
    }

    func widgetChallenge(_ state: ChallengeState) -> JourneySnapshot.Challenge {
        let kind = state.challenge.kind
        let measure = state.measure
        let outlook = outlook(of: state)
        return JourneySnapshot.Challenge(
            id: state.challenge.code + "@" + String(Int(state.start.timeIntervalSince1970)),
            title: kind.title, detail: detail(of: state), symbol: kind.symbol,
            tint: kind.theme.tint, xp: kind.xp, measure: progressCaption(of: state),
            value: measure.value, target: measure.target, unit: measure.unit.widgetUnit,
            progress: outlook?.progress ?? state.finalProgress, elapsed: outlook?.elapsed,
            pace: outlook?.pace?.widgetPace,
            paceTitle: outlook?.pace.map { paceTitle($0, of: state) }, starts: state.from,
            ends: state.end,
            outcome: state.widgetOutcome)
    }

    func publish(status: JourneySnapshot.Status? = nil) async {
        guard let journeyStore else { return }
        let stored = try? journeyStore.read()
        let snapshot = widgetSnapshot(status: status ?? stored?.status ?? .active)
        if snapshot != stored {
            if let snapshot { try? journeyStore.write(snapshot) } else { try? journeyStore.clear() }
            WidgetCenter.shared.reloadTimelines(ofKind: JourneySnapshot.kind)
        }
        #if os(iOS)
            await JourneyActivities.sync(snapshot, now: now(), defaults: defaults)
        #endif
    }
}

extension Challenge.Theme {
    var tint: JourneySnapshot.Tint {
        switch self {
        case .spendLess: .olive
        case .limits: .orange
        case .habits: .teal
        case .budgets: .denim
        }
    }
}

extension ChallengeMeasure.Unit {
    fileprivate var widgetUnit: JourneySnapshot.Challenge.Unit {
        switch self {
        case .money: .money
        case .days: .days
        case .count: .count
        case .score: .score
        }
    }
}

extension ChallengeOutlook.Pace {
    fileprivate var widgetPace: JourneySnapshot.Challenge.Pace {
        switch self {
        case .steady: .steady
        case .fast: .fast
        case .over: .over
        }
    }
}

extension ChallengeState {
    fileprivate var widgetOutcome: JourneySnapshot.Challenge.Outcome {
        switch status {
        case .completed: .completed
        case .failed, .abandoned: .failed
        case .active: .active
        }
    }

    fileprivate var finalProgress: Double {
        if status == .completed { return 1 }
        guard measure.target > 0 else { return 0 }
        return min(max(Double(measure.value) / Double(measure.target), 0), 1)
    }
}
