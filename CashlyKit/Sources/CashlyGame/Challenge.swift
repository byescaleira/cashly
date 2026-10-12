import CashlyDomain
import Foundation

public struct Challenge: Hashable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case noSpendWeek, cap, blueMonth, everyDay, lessThanLastMonth

        public var xp: Int {
            switch self {
            case .noSpendWeek: 100
            case .cap, .lessThanLastMonth: 150
            case .blueMonth: 200
            case .everyDay: 300
            }
        }

        public var needsCategory: Bool {
            self == .noSpendWeek || self == .cap || self == .lessThanLastMonth
        }
    }

    public let kind: Kind
    public let categoryID: String?
    public let limit: Int64?

    public init(kind: Kind, categoryID: String? = nil, limit: Int64? = nil) {
        self.kind = kind
        self.categoryID = categoryID
        self.limit = limit
    }

    public init?(code: String) {
        let parts = code.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard let first = parts.first, let kind = Kind(rawValue: first) else { return nil }
        let category = parts.count > 1 && !parts[1].isEmpty ? parts[1] : nil
        let limit = parts.count > 2 ? Int64(parts[2]) : nil
        guard !kind.needsCategory || category != nil, kind != .cap || limit != nil else {
            return nil
        }
        self.init(kind: kind, categoryID: category, limit: limit)
    }

    public var code: String {
        [kind.rawValue, categoryID ?? "", limit.map(String.init) ?? ""].joined(separator: "|")
    }
}

public struct ChallengeState: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case active(progress: Double)
        case completed
        case failed
        case abandoned
    }

    public let challenge: Challenge
    public let start: Date
    public let end: Date
    public let status: Status

    public var xp: Int { status == .completed ? challenge.kind.xp : 0 }
}

extension ChallengeState {
    static func all(in snapshot: GameSnapshot) -> [ChallengeState] {
        let markers = snapshot.events.filter {
            $0.kind == .challengeStarted || $0.kind == .challengeAbandoned
        }
        return markers.enumerated().compactMap { index, event in
            guard event.kind == .challengeStarted, let challenge = Challenge(code: event.value)
            else {
                return nil
            }
            let stop = markers.dropFirst(index + 1).first?.date
            return evaluate(challenge, start: event.date, stoppedAt: stop, in: snapshot)
        }
    }

    static func evaluate(
        _ challenge: Challenge, start: Date, stoppedAt stop: Date?, in snapshot: GameSnapshot
    ) -> ChallengeState {
        let calendar = snapshot.calendar
        let startDay = snapshot.day(start)
        let month = YearMonth(start)
        let monthEnd = month.adding(months: 1).startDate
        let end =
            challenge.kind == .noSpendWeek
            ? calendar.date(byAdding: .day, value: 7, to: startDay) ?? monthEnd : monthEnd
        let now = stop.map { min($0, snapshot.today) } ?? snapshot.today
        let finished = now >= end
        let status: Status
        switch challenge.kind {
        case .noSpendWeek:
            let spent = snapshot.spent(
                categoryID: challenge.categoryID ?? "", from: startDay, to: min(end, now))
            let days = calendar.dateComponents([.day], from: startDay, to: now).day ?? 0
            status =
                spent > 0 ? .failed : finished ? .completed : .active(progress: Double(days) / 7)
        case .cap:
            let limit = challenge.limit ?? 0
            let spent = snapshot.spent(in: month, categoryID: challenge.categoryID)
            status =
                spent > limit
                ? .failed
                : finished
                    ? .completed : .active(progress: limit > 0 ? Double(spent) / Double(limit) : 0)
        case .blueMonth:
            let score = snapshot.score(in: month) ?? 0
            status =
                finished
                ? (score >= GameEngine.blueScore ? .completed : .failed)
                : .active(progress: elapsed(from: month.startDate, to: end, now: now, calendar))
        case .everyDay:
            let tracked = snapshot.trackedDays
            var cursor = startDay
            var missed = false
            while cursor < min(end, snapshot.day(now)) {
                if !tracked.contains(cursor) { missed = true }
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? end
            }
            status =
                missed
                ? .failed
                : finished
                    ? .completed
                    : .active(progress: elapsed(from: startDay, to: end, now: now, calendar))
        case .lessThanLastMonth:
            let spent = snapshot.spent(in: month, categoryID: challenge.categoryID)
            let previous = snapshot.spent(
                in: month.adding(months: -1), categoryID: challenge.categoryID)
            status =
                finished
                ? (spent < previous ? .completed : .failed)
                : .active(progress: previous > 0 ? Double(spent) / Double(previous) : 0)
        }
        let resolved: Status =
            if stop != nil, case .active = status { .abandoned } else { status }
        return ChallengeState(challenge: challenge, start: start, end: end, status: resolved)
    }

    private static func elapsed(from start: Date, to end: Date, now: Date, _ calendar: Calendar)
        -> Double
    {
        let total = max(calendar.dateComponents([.day], from: start, to: end).day ?? 1, 1)
        let done = calendar.dateComponents([.day], from: start, to: now).day ?? 0
        return min(max(Double(done) / Double(total), 0), 1)
    }
}
