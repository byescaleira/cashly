import CashlyDomain
import Foundation

public struct ChallengeMeasure: Equatable, Sendable {
    public enum Unit: Equatable, Sendable {
        case money, days, count, score
    }

    public let value: Int64
    public let target: Int64
    public let unit: Unit

    public init(_ value: Int64, of target: Int64, _ unit: Unit) {
        self.value = value
        self.target = target
        self.unit = unit
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
    public let from: Date
    public let end: Date
    public let status: Status
    public let measure: ChallengeMeasure

    public var xp: Int { status == .completed ? challenge.kind.xp : 0 }

    public var isFinished: Bool { status == .completed || status == .failed }
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
        let run = ChallengeRun(challenge: challenge, start: start, stop: stop, snapshot: snapshot)
        let (status, measure) = run.outcome()
        let resolved: Status =
            if stop != nil, case .active = status { .abandoned } else { status }
        return ChallengeState(
            challenge: challenge, start: start, from: run.period.start, end: run.period.end,
            status: resolved, measure: measure)
    }
}

struct ChallengeRun {
    let challenge: Challenge
    let start: Date
    let snapshot: GameSnapshot
    let period: DateInterval
    let startDay: Date
    let now: Date
    let horizon: Date

    init(challenge: Challenge, start: Date, stop: Date?, snapshot: GameSnapshot) {
        let calendar = snapshot.calendar
        self.challenge = challenge
        self.start = start
        self.snapshot = snapshot
        period = challenge.kind.period(startingAt: start, calendar: calendar)
        startDay = calendar.startOfDay(for: start)
        now = stop.map { min($0, snapshot.today) } ?? snapshot.today
        let tomorrow =
            calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        horizon = min(period.end, stop == nil ? tomorrow : now)
    }

    var calendar: Calendar { snapshot.calendar }
    var finished: Bool { now >= period.end }
    var nowDay: Date { calendar.startOfDay(for: now) }
    var month: YearMonth { YearMonth(start) }
    var category: String { challenge.categoryID ?? "" }

    var elapsed: Double {
        let total = max(days(from: period.start, to: period.end), 1)
        return min(max(Double(days(from: period.start, to: now)) / Double(total), 0), 1)
    }

    func days(from start: Date, to end: Date) -> Int {
        calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    func dayList(from start: Date, to end: Date) -> [Date] {
        var result: [Date] = []
        var cursor = calendar.startOfDay(for: start)
        while cursor < end {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }

    func atEnd(_ success: Bool, progress: Double) -> ChallengeState.Status {
        finished ? (success ? .completed : .failed) : .active(progress: progress)
    }

    func within(_ spent: Int64, of target: Int64) -> ChallengeState.Status {
        if spent > target { return .failed }
        if finished { return .completed }
        return .active(progress: target > 0 ? Double(spent) / Double(target) : 0)
    }

    var missedDay: Bool {
        let tracked = snapshot.trackedDays
        return dayList(from: period.start, to: min(period.end, nowDay)).contains {
            !tracked.contains($0)
        }
    }

    var trackedSoFar: Int64 {
        let tracked = snapshot.trackedDays
        return Int64(dayList(from: period.start, to: horizon).filter(tracked.contains).count)
    }

    var periodDays: Int64 { Int64(max(days(from: period.start, to: period.end), 1)) }

    var cleanDays: Int64 {
        Int64(min(max(days(from: period.start, to: nowDay), 0), Int(periodDays)))
    }
}
