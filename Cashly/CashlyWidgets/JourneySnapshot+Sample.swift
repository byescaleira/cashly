import CashlyDomain
import Foundation

extension JourneySnapshot {
    nonisolated static var sample: JourneySnapshot {
        JourneySnapshot(
            userID: "sample", status: .active, currencyCode: "BRL",
            level: Level(
                number: 7, title: String(localized: "Planner"), xpIntoLevel: 340,
                xpForNextLevel: 700, totalXP: 2_440),
            streak: Streak(
                current: 12, best: 18, freezes: 1, isTodayTracked: true,
                day: Calendar.current.startOfDay(for: .now)),
            missions: sampleMissions, challenge: sampleChallenge,
            nextAchievement: Achievement(
                title: String(localized: "One Week Strong"), symbol: "flame.fill", value: 5,
                target: 7, xp: 100))
    }

    nonisolated var withoutChallenge: JourneySnapshot {
        JourneySnapshot(
            userID: userID, status: status, currencyCode: currencyCode, level: level,
            streak: Streak(
                current: streak.current, best: streak.best, freezes: streak.freezes,
                isTodayTracked: false, day: streak.day),
            missions: missions, nextAchievement: nextAchievement)
    }

    nonisolated func with(status: Status) -> JourneySnapshot {
        JourneySnapshot(
            userID: userID, status: status, currencyCode: currencyCode, level: level,
            streak: streak, missions: missions, challenge: challenge,
            lastChallenge: lastChallenge, nextAchievement: nextAchievement)
    }

    nonisolated private static var sampleMissions: [Mission] {
        [
            Mission(
                id: "recordFive", title: String(localized: "Record \(5) transactions"),
                symbol: "plus.circle.fill", value: 5, target: 5, xp: 25),
            Mission(
                id: "trackFourDays", title: String(localized: "Follow your money on \(4) days"),
                symbol: "calendar", value: 2, target: 4, xp: 25),
            Mission(
                id: "noSpendDay", title: String(localized: "Mark a no-spend day"),
                symbol: "hand.raised.fill", value: 0, target: 1, xp: 25),
        ]
    }

    nonisolated static var sampleChallenge: Challenge {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let money = { (value: Int64) in
            (Decimal(value) / 100).formatted(.currency(code: "BRL").precision(.fractionLength(0)))
        }
        return Challenge(
            id: "cap|food|64000@0", title: String(localized: "Spending Cap"),
            detail: String(localized: "Keep one category under an amount this month."),
            symbol: "gauge.with.dots.needle.33percent", tint: .orange, xp: 150,
            measure: String(localized: "\(money(32_000)) of \(money(64_000))"), value: 32_000,
            target: 64_000, unit: .money, progress: 0.5, elapsed: 0.45, pace: .steady,
            paceTitle: String(localized: "On pace with the month"),
            starts: calendar.date(byAdding: .day, value: -13, to: today) ?? today,
            ends: calendar.date(byAdding: .day, value: 17, to: today) ?? today, outcome: .active)
    }
}
