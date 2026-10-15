import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension JourneySnapshot.Tint {
    public var color: Color {
        switch self {
        case .orange: .retroOrange
        case .olive: .retroOlive
        case .teal: .retroTeal
        case .denim: .retroDenim
        case .mustard: .retroMustard
        case .rust: .retroRust
        }
    }
}

extension JourneySnapshot.Challenge {
    public var color: Color { tone.color }

    var paceSymbol: String {
        switch pace {
        case .steady: "checkmark.circle"
        case .fast: "hare"
        case .over: "exclamationmark.triangle"
        case nil: "hourglass"
        }
    }

    public func shortMeasure(currencyCode: String) -> String {
        switch unit {
        case .money:
            (Decimal(value) / 100).formatted(
                .currency(code: currencyCode).precision(.fractionLength(0)).locale(.app))
        case .score: value.formatted(.number.locale(.app))
        case .days, .count: "\(min(value, target))/\(target)"
        }
    }
}

extension JourneySnapshot {
    public static var sample: JourneySnapshot {
        JourneySnapshot(
            userID: "sample", status: .active, currencyCode: Money.currencyCode,
            level: Level(
                number: 7, title: String(appLocalized: "Planner"), xpIntoLevel: 340,
                xpForNextLevel: 700, totalXP: 2_440),
            streak: Streak(
                current: 12, best: 18, freezes: 1, isTodayTracked: true,
                day: Calendar.current.startOfDay(for: .now)),
            missions: sampleMissions, challenge: sampleChallenge,
            nextAchievement: Achievement(
                title: String(appLocalized: "One Week Strong"), symbol: "flame.fill", value: 5,
                target: 7, xp: 100))
    }

    public var withoutChallenge: JourneySnapshot {
        JourneySnapshot(
            userID: userID, status: status, currencyCode: currencyCode, level: level,
            streak: Streak(
                current: streak.current, best: streak.best, freezes: streak.freezes,
                isTodayTracked: false, day: streak.day),
            missions: missions, nextAchievement: nextAchievement)
    }

    public func with(status: Status) -> JourneySnapshot {
        JourneySnapshot(
            userID: userID, status: status, currencyCode: currencyCode, level: level,
            streak: streak, missions: missions, challenge: challenge,
            lastChallenge: lastChallenge, nextAchievement: nextAchievement)
    }

    private static var sampleMissions: [Mission] {
        [
            Mission(
                id: "recordFive", title: String(appLocalized: "Record \(5) transactions"),
                symbol: "plus.circle.fill", value: 5, target: 5, xp: 25),
            Mission(
                id: "trackFourDays", title: String(appLocalized: "Follow your money on \(4) days"),
                symbol: "calendar", value: 2, target: 4, xp: 25),
            Mission(
                id: "noSpendDay", title: String(appLocalized: "Mark a no-spend day"),
                symbol: "hand.raised.fill", value: 0, target: 1, xp: 25),
        ]
    }

    public static var sampleChallenge: Challenge {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let money = { (value: Int64) in
            (Decimal(value) / 100).formatted(
                .currency(code: Money.currencyCode).precision(.fractionLength(0)).locale(.app))
        }
        return Challenge(
            id: "cap|food|64000@0", title: String(appLocalized: "Spending Cap"),
            detail: String(appLocalized: "Keep one category under an amount this month."),
            symbol: "gauge.with.dots.needle.33percent", tint: .orange, xp: 150,
            measure: String(appLocalized: "\(money(32_000)) of \(money(64_000))"), value: 32_000,
            target: 64_000, unit: .money, progress: 0.5, elapsed: 0.45, pace: .steady,
            paceTitle: String(appLocalized: "On pace with the month"),
            starts: calendar.date(byAdding: .day, value: -13, to: today) ?? today,
            ends: calendar.date(byAdding: .day, value: 17, to: today) ?? today, outcome: .active)
    }
}
