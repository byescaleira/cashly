import CashlyDomain
import Foundation

public struct IntentActions: Sendable {
    public struct MonthSummary: Equatable, Sendable {
        public let month: YearMonth
        public let spent: Money
        public let planned: Money
        public let income: Money

        public var available: Money { Money(minorUnits: planned.minorUnits - spent.minorUnits) }
    }

    public struct CategoryRemaining: Equatable, Sendable {
        public let category: CashlyDomain.Category
        public let spent: Money
        public let planned: Money?

        public var remaining: Money? {
            planned.map { Money(minorUnits: $0.minorUnits - spent.minorUnits) }
        }
    }

    private let repositories: Repositories
    private let user: User
    private let now: @Sendable () -> Date

    public init(
        repositories: Repositories, user: User, now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.repositories = repositories
        self.user = user
        self.now = now
    }

    public func categories() async throws -> [CashlyDomain.Category] {
        try await repositories.dashboard.snapshot(month: nil).categories
            .filter { $0.user.id == user.id }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func tags() async throws -> [Tag] {
        try await repositories.dashboard.snapshot(month: nil).tags
            .filter { $0.user.id == user.id }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func pendingBills(limit: Int = 50) async throws -> [Transaction] {
        try await repositories.dashboard.page(
            query: TransactionQuery(statuses: [.pendingToPay], kinds: [.expense]), after: nil,
            limit: limit
        ).items
    }

    public func participants() async throws -> [User] {
        try await repositories.users.users().filter { $0.id != user.id }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func addExpense(
        amount: Double, categoryID: String?, summary: String, date: Date?, tagIDs: Set<String> = []
    ) async throws -> Transaction {
        let options = try await categories()
        guard let category = options.first(where: { $0.id == categoryID }) ?? options.first else {
            throw CashlyError.invalidInput(
                String(appLocalized: "Create a category in Cashly before adding expenses."))
        }
        return try await add(
            TransactionRequest(
                amount: amount, categoryID: category.id, summary: summary, date: date,
                tagIDs: tagIDs))
    }

    public func add(_ request: TransactionRequest) async throws -> Transaction {
        let money = try Money(validating: request.amount)
        guard money.minorUnits > 0 else {
            throw CashlyError.invalidInput(String(appLocalized: "The amount must be positive."))
        }
        let options = try await categories()
        guard !options.isEmpty else {
            throw CashlyError.invalidInput(
                String(appLocalized: "Create a category in Cashly before adding expenses."))
        }
        guard let category = options.first(where: { $0.id == request.categoryID }) else {
            throw CashlyError.invalidInput(
                String(appLocalized: "Choose one of the categories of this profile."))
        }
        let available = try await tags()
        guard request.tagIDs.isSubset(of: Set(available.map(\.id))) else {
            throw CashlyError.invalidInput(
                String(appLocalized: "Choose tags of this profile."))
        }
        if let installments = request.installments, !(1...1200).contains(installments) {
            throw CashlyError.invalidInput(
                String(appLocalized: "The number of installments must be between 1 and 1,200."))
        }
        let text = request.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = text.count >= 3 ? text : category.name
        let matched = available.filter { TagSuggestion.matches($0.name, in: summary) }.map(\.id)
        let id = UUID().uuidString
        let participants = try await split(request, total: money, transactionID: id)
        let allocation = try TransactionAllocation.resolve(total: money, participants: participants)
        let transaction = Transaction(
            id: id,
            participants: participants.map { participant in
                var participant = participant
                participant.allocatedMoney = allocation.participants[participant.id]
                return participant
            }, category: category, money: money, date: request.date ?? now(), summary: summary,
            status: request.transactionStatus,
            splitMode: participants.isEmpty ? nil : request.splitMode,
            splitValue: participants.isEmpty ? nil : allocation.owner.doubleValue,
            paymentsPlan: request.installments, tagIDs: request.tagIDs.union(matched),
            kind: request.kind)
        try await repositories.transactions.save(transaction)
        return transaction
    }

    private func split(_ request: TransactionRequest, total: Money, transactionID: String)
        async throws -> [Participant]
    {
        guard !request.participantIDs.isEmpty else { return [] }
        guard request.kind == .expense else {
            throw CashlyError.invalidInput(
                String(appLocalized: "Only expenses can be split with other profiles."))
        }
        let others = try await participants()
        var seen: Set<String> = []
        let ids = request.participantIDs.filter { seen.insert($0).inserted }
        let users = try ids.map { id in
            guard let user = others.first(where: { $0.id == id }) else {
                throw CashlyError.invalidInput(
                    String(appLocalized: "Choose who splits it among the other profiles."))
            }
            return user
        }
        let value = try shareValue(request, count: users.count)
        return users.map { user in
            Participant(
                id: UUID().uuidString, user: user, splitMode: request.splitMode,
                splitValue: value, status: .settled, transaction: transactionID)
        }
    }

    private func shareValue(_ request: TransactionRequest, count: Int) throws -> Double {
        switch request.splitMode {
        case .equal:
            return Double(count + 1)
        case .payerBased:
            throw CashlyError.invalidInput(
                String(appLocalized: "Choose how to split the transaction."))
        case .percentage:
            guard let share = request.share, share.isFinite, (0...100).contains(share) else {
                throw CashlyError.invalidInput(
                    String(
                        appLocalized: "Tell each profile's share as a percentage from 0 to 100."
                    ))
            }
            return share / 100
        case .fixedAmount:
            guard let share = request.share, share.isFinite, share >= 0 else {
                throw CashlyError.invalidInput(
                    String(appLocalized: "Tell the amount each profile pays."))
            }
            return try Money(validating: share).doubleValue
        }
    }

    public func monthSummary(month: YearMonth? = nil) async throws -> MonthSummary {
        let month = month ?? YearMonth(now())
        let overview = try await repositories.dashboard.overview(
            query: TransactionQuery(month: month))
        return MonthSummary(
            month: month, spent: overview.expensesTotal, planned: overview.budgetsTotal,
            income: overview.incomeTotal)
    }

    public func remaining(categoryID: String, month: YearMonth? = nil) async throws
        -> CategoryRemaining
    {
        let month = month ?? YearMonth(now())
        guard let category = try await categories().first(where: { $0.id == categoryID }) else {
            throw CashlyError.missingRecord
        }
        let overview = try await repositories.dashboard.overview(
            query: TransactionQuery(month: month))
        let planned = overview.budgets.filter { $0.category.id == categoryID }.map(\.money)
        return CategoryRemaining(
            category: category, spent: overview.categoryExpenses[categoryID] ?? .zero,
            planned: planned.isEmpty
                ? nil : Money(minorUnits: planned.map(\.minorUnits).reduce(0, +)))
    }

    public func postpone(transactionID: String, days: Int = 1) async throws -> Transaction {
        guard var transaction = try await repositories.transactions.transaction(id: transactionID),
            let date = CashlyCalendar.current.date(
                byAdding: .day, value: days, to: transaction.date)
        else { throw CashlyError.missingRecord }
        transaction.date = date
        try await repositories.transactions.save(transaction)
        return transaction
    }

    public func markPaid(transactionID: String) async throws -> Transaction {
        guard var transaction = try await repositories.transactions.transaction(id: transactionID)
        else { throw CashlyError.missingRecord }
        transaction.status = .settled
        try await repositories.transactions.save(transaction)
        return transaction
    }
}
