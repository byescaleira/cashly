import CashlyDomain
import Foundation

public struct Mission: Equatable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case recordFive, recordTen, trackFourDays, trackSixDays, noSpendDay, useTags, splitExpense
        case backup

        public var target: Int {
            switch self {
            case .recordFive: 5
            case .recordTen: 10
            case .trackFourDays: 4
            case .trackSixDays: 6
            case .noSpendDay, .splitExpense, .backup: 1
            case .useTags: 2
            }
        }
    }

    public static let xp = 25
    public static let perWeek = 3

    public let kind: Kind
    public let value: Int

    public var isCompleted: Bool { value >= kind.target }
    public var progress: Double { min(Double(value) / Double(kind.target), 1) }
}

extension Mission {
    static func week(containing date: Date, in snapshot: GameSnapshot) -> [Mission] {
        let start = weekStart(of: date, snapshot.calendar)
        let end = snapshot.calendar.date(byAdding: .day, value: 7, to: start) ?? start
        let events = snapshot.events.filter { $0.date >= start && $0.date < end }
        let recorded = events.filter { $0.kind == .transactionRecorded }.map(\.value)
        let transactions = Dictionary(
            snapshot.transactions.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let tracked = snapshot.trackedDays.filter { $0 >= start && $0 < end }.count
        return kinds(forWeek: weekIndex(start), seed: seed(snapshot.userID)).map {
            kind in
            let value =
                switch kind {
                case .recordFive, .recordTen: recorded.count
                case .trackFourDays, .trackSixDays: tracked
                case .noSpendDay: events.filter { $0.kind == .noSpendDay }.count
                case .useTags: recorded.filter { !(transactions[$0]?.tagIDs.isEmpty ?? true) }.count
                case .splitExpense:
                    recorded.filter { !(transactions[$0]?.participants.isEmpty ?? true) }.count
                case .backup: events.filter { $0.kind == .backupCreated }.count
                }
            return Mission(kind: kind, value: value)
        }
    }

    static func completedXP(in snapshot: GameSnapshot) -> Int {
        guard let first = snapshot.events.first?.date else { return 0 }
        var cursor = weekStart(of: first, snapshot.calendar)
        var total = 0
        while cursor <= snapshot.today {
            total += week(containing: cursor, in: snapshot).filter(\.isCompleted).count * xp
            cursor = snapshot.calendar.date(byAdding: .day, value: 7, to: cursor) ?? snapshot.today
        }
        return total
    }

    static func kinds(forWeek week: Int, seed: Int) -> [Kind] {
        var pool = Kind.allCases
        var state = UInt64(truncatingIfNeeded: week &* 7919 &+ seed) | 1
        var chosen: [Kind] = []
        while chosen.count < perWeek && !pool.isEmpty {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let index = Int((state >> 33) % UInt64(pool.count))
            let kind = pool.remove(at: index)
            if chosen.contains(where: { $0.isSibling(of: kind) }) { continue }
            chosen.append(kind)
        }
        return chosen
    }

    static func weekStart(of date: Date, _ calendar: Calendar) -> Date {
        var monday = calendar
        monday.firstWeekday = 2
        return monday.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
    }

    static func weekIndex(_ start: Date) -> Int {
        Int((start.timeIntervalSinceReferenceDate / 604_800).rounded())
    }

    static func seed(_ userID: String) -> Int {
        userID.unicodeScalars.reduce(17) { ($0 &* 31 &+ Int($1.value)) % 1_000_003 }
    }
}

extension Mission.Kind {
    fileprivate func isSibling(of other: Mission.Kind) -> Bool {
        let groups: [Set<Mission.Kind>] = [
            [.recordFive, .recordTen], [.trackFourDays, .trackSixDays],
        ]
        return groups.contains { $0.contains(self) && $0.contains(other) }
    }
}
