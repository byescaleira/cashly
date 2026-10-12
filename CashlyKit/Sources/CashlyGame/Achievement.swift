import CashlyDomain
import Foundation

public enum Achievement: String, CaseIterable, Identifiable, Sendable {
    case firstTransaction, firstCategory, firstBudget, firstTag, firstSplit, firstImport,
        firstBackup
    case streak7, streak30, streak100, streak365
    case blueMonth, blueRun3, blueRun6, blueRun12, perfectMonth
    case transactions100, transactions500, transactions1000, transactions5000
    case tagsInUse5, fullyBudgeted, allGuides
    case splits10, splits50
    case challenges1, challenges5, challenges12
    case level10, level25
    case theAnswer, sequence, halloween, newYear, earlyBird

    public enum Group: CaseIterable, Sendable {
        case firstSteps, consistency, inTheBlue, volume, organization, together, challenges, levels
        case secret
    }

    public enum Tier: Int, Comparable, Sendable {
        case bronze, silver, gold

        public static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public var id: String { rawValue }

    public var group: Group {
        switch self {
        case .firstTransaction, .firstCategory, .firstBudget, .firstTag, .firstSplit, .firstImport,
            .firstBackup:
            .firstSteps
        case .streak7, .streak30, .streak100, .streak365: .consistency
        case .blueMonth, .blueRun3, .blueRun6, .blueRun12, .perfectMonth: .inTheBlue
        case .transactions100, .transactions500, .transactions1000, .transactions5000: .volume
        case .tagsInUse5, .fullyBudgeted, .allGuides: .organization
        case .splits10, .splits50: .together
        case .challenges1, .challenges5, .challenges12: .challenges
        case .level10, .level25: .levels
        case .theAnswer, .sequence, .halloween, .newYear, .earlyBird: .secret
        }
    }

    public var tier: Tier {
        switch self {
        case .streak30, .blueRun3, .perfectMonth, .transactions500, .fullyBudgeted, .allGuides,
            .splits50, .challenges5, .level10:
            .silver
        case .streak100, .streak365, .blueRun6, .blueRun12, .transactions1000, .transactions5000,
            .challenges12, .level25:
            .gold
        default: .bronze
        }
    }

    public var xp: Int {
        switch (group, tier) {
        case (.firstSteps, _), (.secret, _): 50
        case (_, .bronze): 100
        case (_, .silver): 250
        case (_, .gold):
            self == .streak365 || self == .blueRun12 || self == .transactions5000 ? 500 : 400
        }
    }

    public var isSecret: Bool { group == .secret }

    public var target: Int {
        switch self {
        case .streak7: 7
        case .streak30: 30
        case .streak100: 100
        case .streak365: 365
        case .blueRun3: 3
        case .blueRun6: 6
        case .blueRun12: 12
        case .transactions100: 100
        case .transactions500: 500
        case .transactions1000: 1000
        case .transactions5000: 5000
        case .tagsInUse5, .challenges5: 5
        case .splits10, .level10: 10
        case .splits50: 50
        case .challenges12: 12
        case .level25: 25
        default: 1
        }
    }
}

public struct AchievementState: Equatable, Identifiable, Sendable {
    public let achievement: Achievement
    public let value: Int

    public var id: String { achievement.id }
    public var isUnlocked: Bool { value >= achievement.target }
    public var progress: Double { min(Double(value) / Double(achievement.target), 1) }
}

struct AchievementFacts {
    let snapshot: GameSnapshot
    let bestStreak: Int
    let blueMonths: [YearMonth]
    let perfectMonths: Int
    let completedChallenges: Int
    let level: Int

    func value(of achievement: Achievement) -> Int {
        let ledger = snapshot.ledger
        let transactions = snapshot.transactions
        switch achievement {
        case .firstTransaction, .transactions100, .transactions500, .transactions1000,
            .transactions5000:
            return transactions.count
        case .firstCategory: return ledger.categories.count
        case .firstBudget: return ledger.budgets.count
        case .firstTag: return ledger.tags.count
        case .firstSplit, .splits10, .splits50:
            return transactions.filter { !$0.participants.isEmpty }.count
        case .firstImport: return snapshot.events(.spreadsheetImported).count
        case .firstBackup: return snapshot.events(.backupCreated).count
        case .streak7, .streak30, .streak100, .streak365: return bestStreak
        case .blueMonth: return blueMonths.count
        case .blueRun3, .blueRun6, .blueRun12: return longestRun(blueMonths)
        case .perfectMonth: return perfectMonths
        case .tagsInUse5: return Set(transactions.flatMap(\.tagIDs)).count
        case .fullyBudgeted:
            let month = ledger.currentMonth
            let budgeted = Set(ledger.budgets.filter { $0.month == month }.map(\.category.id))
            return !ledger.categories.isEmpty
                && ledger.categories.allSatisfy { budgeted.contains($0.id) } ? 1 : 0
        case .allGuides:
            let done = Set(snapshot.events(.guideCompleted).map(\.value)).count
            return snapshot.guideCount > 0 && done >= snapshot.guideCount ? 1 : 0
        case .challenges1, .challenges5, .challenges12: return completedChallenges
        case .level10, .level25: return level
        case .theAnswer: return transactions.contains { $0.money.minorUnits == 4_200 } ? 1 : 0
        case .sequence: return transactions.contains { $0.money.minorUnits == 123_456 } ? 1 : 0
        case .halloween: return transactions.contains { isDay($0.date, day: 31, month: 10) } ? 1 : 0
        case .newYear: return transactions.contains { isDay($0.date, day: 1, month: 1) } ? 1 : 0
        case .earlyBird:
            return snapshot.events(.transactionRecorded).contains {
                let parts = snapshot.calendar.dateComponents([.hour, .minute], from: $0.date)
                return parts.hour == 4 && parts.minute == 44
            } ? 1 : 0
        }
    }

    private func isDay(_ date: Date, day: Int, month: Int) -> Bool {
        let parts = snapshot.calendar.dateComponents([.day, .month], from: date)
        return parts.day == day && parts.month == month
    }

    private func longestRun(_ months: [YearMonth]) -> Int {
        var best = 0
        var run = 0
        var previous: YearMonth?
        for month in months.sorted() {
            run = previous.map { month.months(since: $0) == 1 } == true ? run + 1 : 1
            best = max(best, run)
            previous = month
        }
        return best
    }
}
