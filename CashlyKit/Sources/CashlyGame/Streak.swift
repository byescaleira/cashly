import CashlyDomain
import Foundation

public struct Streak: Equatable, Sendable {
    public static let freezeRun = 14
    public static let weekLength = 7

    public struct Day: Equatable, Sendable {
        public enum State: Equatable, Sendable {
            case tracked, covered, missed
        }

        public let date: Date
        public let state: State
    }

    public let current: Int
    public let best: Int
    public let freezes: Int
    public let isTodayTracked: Bool
    public let restorable: Int
    public let week: [Day]

    init(_ snapshot: GameSnapshot) {
        let calendar = snapshot.calendar
        let tracked = snapshot.trackedDays
        let today = snapshot.day(snapshot.today)
        let credits = Dictionary(
            grouping: snapshot.events(.freezesCredited), by: { snapshot.day($0.date) }
        ).mapValues { $0.reduce(0) { $0 + $1.count } }
        let restores = snapshot.events(.streakRestored).map { snapshot.day($0.date) }
        var run = 0
        var best = 0
        var freezes = 0
        var earned: Set<YearMonth> = []
        var covered: Set<Date> = []
        var lost = (run: 0, day: Date.distantPast)
        var cursor = (tracked.union(credits.keys)).min() ?? today
        while cursor <= today {
            freezes += credits[cursor] ?? 0
            if tracked.contains(cursor) {
                run += 1
                best = max(best, run)
                if run >= Self.freezeRun, earned.insert(YearMonth(cursor)).inserted { freezes += 1 }
            } else if cursor < today {
                let restored = restores.contains { restore in
                    restore > cursor
                        && calendar.dateComponents([.day], from: cursor, to: restore).day ?? 3 <= 2
                }
                if restored {
                    covered.insert(cursor)
                } else if freezes > 0 && run > 0 {
                    freezes -= 1
                    covered.insert(cursor)
                } else {
                    if run > 0 { lost = (run, cursor) }
                    run = 0
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        current = run
        self.best = best
        self.freezes = freezes
        isTodayTracked = tracked.contains(today)
        let age = calendar.dateComponents([.day], from: lost.day, to: today).day ?? 3
        restorable = age <= 2 ? lost.run : 0
        week = (1 - Self.weekLength...0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }.map { date in
            Day(
                date: date,
                state: tracked.contains(date)
                    ? .tracked : covered.contains(date) ? .covered : .missed
            )
        }
    }
}
