import CashlyDomain
import Foundation
import Testing

struct OverviewAccumulatorTests {
    private let owner = User(id: "owner", name: "Owner", photo: "")
    private let friend = User(id: "friend", name: "Friend", photo: "")
    private var food: CashlyDomain.Category {
        Category(id: "food", user: owner, name: "Food", color: "", icon: "")
    }
    private var home: CashlyDomain.Category {
        Category(id: "home", user: owner, name: "Home", color: "", icon: "")
    }

    private func month(_ year: Int, _ month: Int) throws -> YearMonth {
        try #require(YearMonth(year: year, month: month))
    }

    private func budget(
        _ id: String, _ category: CashlyDomain.Category, cents: Int64, _ month: YearMonth,
        conflicted: Bool = false
    ) -> Budget {
        Budget(
            id: id, money: Money(minorUnits: cents), category: category, month: month,
            summary: "Plano", isConflicted: conflicted)
    }

    private func transaction(
        _ id: String, _ category: CashlyDomain.Category, cents: Int64, on date: Date,
        kind: TransactionKind = .expense, status: TransactionStatus = .settled, plan: Int? = nil,
        tags: Set<String> = [], participants: [Participant] = []
    ) -> Transaction {
        Transaction(
            id: id, participants: participants, category: category,
            money: Money(minorUnits: cents), date: date, summary: "Registro", status: status,
            splitMode: participants.isEmpty ? nil : .equal, splitValue: nil, paymentsPlan: plan,
            tagIDs: tags, kind: kind)
    }

    @Test func totalsBudgetsAndExpensesForMonth() throws {
        let january = try month(2026, 1)
        var accumulator = try OverviewAccumulator(
            budgets: [
                budget("b1", food, cents: 20000, january),
                budget("b2", home, cents: 10000, january),
                budget("b3", food, cents: 99999, january.adding(months: 1)),
            ],
            month: january, categoryIDs: [], pendingReferences: 2)
        try accumulator.add(transaction("t1", food, cents: 10001, on: january.startDate))
        try accumulator.add(
            transaction("t2", food, cents: 10001, on: january.startDate, plan: 3, tags: ["tag"]))
        try accumulator.add(
            transaction("t3", home, cents: 120005, on: january.startDate, kind: .income))
        let overview = try accumulator.result()

        #expect(overview.budgets.map(\.id) == ["b1", "b2"])
        #expect(overview.budgetsTotal.minorUnits == 30000)
        #expect(overview.expensesTotal.minorUnits == 13335)
        #expect(overview.incomeTotal.minorUnits == 120005)
        #expect(overview.netTotal.minorUnits == 106670)
        #expect(overview.categoryExpenses["food"]?.minorUnits == 13335)
        #expect(overview.budgetExpenses["b1"]?.minorUnits == 13335)
        #expect(overview.tagExpenses["tag"]?.minorUnits == 3334)
        #expect(overview.transactionCount == 3)
        #expect(overview.expenseDayCount == 1)
        #expect(overview.pendingReferences == 2)
    }

    @Test func installmentsReachBudgetsOfEveryMonthWithoutFilter() throws {
        let january = try month(2026, 1)
        let february = january.adding(months: 1)
        var accumulator = try OverviewAccumulator(
            budgets: [
                budget("jan", food, cents: 5000, january),
                budget("feb", food, cents: 5000, february),
            ],
            month: nil, categoryIDs: [], pendingReferences: 0)
        try accumulator.add(transaction("t", food, cents: 10001, on: january.startDate, plan: 3))
        let overview = try accumulator.result()

        #expect(overview.budgetExpenses["jan"]?.minorUnits == 3334)
        #expect(overview.budgetExpenses["feb"]?.minorUnits == 3334)
        #expect(overview.expensesTotal.minorUnits == 10001)
    }

    @Test func conflictedBudgetsAreReportedButNotPlanned() throws {
        let january = try month(2026, 1)
        var accumulator = try OverviewAccumulator(
            budgets: [
                budget("a", food, cents: 1000, january, conflicted: true),
                budget("b", food, cents: 2000, january, conflicted: true),
                budget("c", home, cents: 3000, january),
            ],
            month: january, categoryIDs: [], pendingReferences: 0)
        try accumulator.add(transaction("t", food, cents: 500, on: january.startDate))
        let overview = try accumulator.result()

        #expect(overview.conflicts.count == 1)
        #expect(overview.conflicts.first?.budgets.map(\.id) == ["a", "b"])
        #expect(overview.budgetsTotal.minorUnits == 3000)
        #expect(overview.budgetExpenses.isEmpty)
    }

    @Test func filtersBudgetsByCategory() throws {
        let january = try month(2026, 1)
        let accumulator = try OverviewAccumulator(
            budgets: [
                budget("a", food, cents: 1000, january), budget("b", home, cents: 1, january),
            ],
            month: january, categoryIDs: ["home"], pendingReferences: 0)
        #expect(try accumulator.result().budgets.map(\.id) == ["b"])
    }

    @Test func ranksBiggestTransactionsAndParticipants() throws {
        let january = try month(2026, 1)
        var accumulator = try OverviewAccumulator(
            budgets: [], month: january, categoryIDs: [], pendingReferences: 0)
        let share = Participant(
            id: "p", user: friend, splitMode: .equal, splitValue: 2, status: .pendingToReceive,
            transaction: "shared")
        for index in 0..<6 {
            try accumulator.add(
                transaction(
                    "t\(index)", food, cents: Int64(100 * (index + 1)), on: january.startDate))
        }
        try accumulator.add(
            transaction("shared", food, cents: 1000, on: january.startDate, participants: [share]))
        try accumulator.add(
            transaction("canceled", food, cents: 9999, on: january.startDate, status: .canceled))
        let overview = try accumulator.result()

        #expect(overview.biggestTransactions.map(\.id) == ["t5", "shared", "t4", "t3", "t2"])
        #expect(overview.participantUsers == [friend])
    }

    @Test func countsDistinctExpenseDays() throws {
        let calendar = CashlyCalendar.current
        let first = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 3)))
        let second = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 9)))
        var accumulator = try OverviewAccumulator(
            budgets: [], month: nil, categoryIDs: [], pendingReferences: 0)
        try accumulator.add(transaction("a", food, cents: 100, on: first))
        try accumulator.add(transaction("b", food, cents: 100, on: first.addingTimeInterval(3600)))
        try accumulator.add(transaction("c", food, cents: 100, on: second))
        try accumulator.add(transaction("d", food, cents: 100, on: second, kind: .income))
        #expect(try accumulator.result().expenseDayCount == 2)
    }
}
