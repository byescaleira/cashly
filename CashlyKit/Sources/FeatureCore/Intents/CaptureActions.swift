import CashlyDomain
import Foundation

public struct CaptureActions: Sendable {
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

    private var intents: IntentActions {
        IntentActions(repositories: repositories, user: user, now: now)
    }

    public func categories() async throws -> [CashlyDomain.Category] {
        try await intents.categories()
    }

    public func pending() async throws -> [Capture] {
        try await repositories.captures.captures(status: .pending)
    }

    public func capture(
        amount: Double, merchant: String, card: String? = nil, date: Date? = nil,
        source: Capture.Source = .wallet
    ) async throws -> (capture: Capture, isNew: Bool) {
        let money = try Money(validating: amount)
        guard money.minorUnits > 0 else {
            throw CashlyError.invalidInput(String(appLocalized: "The amount must be positive."))
        }
        var capture = Capture(
            ownerID: user.id, money: money, merchant: merchant, card: card ?? "",
            date: date ?? now(), source: source, createdAt: now())
        guard !capture.merchant.isEmpty else {
            throw CashlyError.invalidInput(
                String(appLocalized: "Tell the merchant of the payment."))
        }
        if let memory = try await repositories.captures.memory(key: capture.merchantKey) {
            capture.suggestedCategoryID = memory.categoryID
            capture.suggestedSummary = memory.summary
            capture.suggestedTagIDs = memory.tagIDs
        } else {
            capture.suggestedCategoryID = try await usage().first?.id
            capture.suggestedSummary = capture.merchant
        }
        let stored = try await repositories.captures.save(capture)
        return (stored, stored.id == capture.id)
    }

    public func frequentCategories(limit: Int = 3) async throws -> [CashlyDomain.Category] {
        let used = try await usage()
        let ids = Set(used.map(\.id))
        let rest = try await categories().filter { !ids.contains($0.id) }
        return Array((used + rest).prefix(limit))
    }

    public func accept(captureID: String, categoryID: String? = nil) async throws
        -> CashlyDomain.Transaction
    {
        guard let capture = try await repositories.captures.capture(id: captureID) else {
            throw CashlyError.missingRecord
        }
        if let linked = capture.transactionID,
            let existing = try await repositories.transactions.transaction(id: linked)
        {
            return existing
        }
        let tags = Set(try await intents.tags().map(\.id))
        let transaction = try await intents.addExpense(
            amount: capture.money.doubleValue,
            categoryID: categoryID ?? capture.suggestedCategoryID,
            summary: capture.suggestedSummary.isEmpty ? capture.merchant : capture.suggestedSummary,
            date: capture.date, tagIDs: capture.suggestedTagIDs.intersection(tags))
        try await link(capture, to: transaction)
        return transaction
    }

    public func link(captureID: String, to transaction: CashlyDomain.Transaction) async throws {
        guard let capture = try await repositories.captures.capture(id: captureID) else {
            throw CashlyError.missingRecord
        }
        try await link(capture, to: transaction)
    }

    public func dismiss(captureID: String) async throws -> Capture {
        guard var capture = try await repositories.captures.capture(id: captureID) else {
            throw CashlyError.missingRecord
        }
        capture.status = .dismissed
        return try await repositories.captures.save(capture)
    }

    private func link(_ capture: Capture, to transaction: CashlyDomain.Transaction) async throws {
        var accepted = capture
        accepted.status = .accepted
        accepted.transactionID = transaction.id
        _ = try await repositories.captures.save(accepted)
        let previous = try await repositories.captures.memory(key: capture.merchantKey)
        try await repositories.captures.remember(
            MerchantMemory(
                key: capture.merchantKey, ownerID: user.id, categoryID: transaction.category.id,
                summary: transaction.summary, tagIDs: transaction.tagIDs,
                count: (previous?.count ?? 0) + 1))
    }

    private func usage() async throws -> [CashlyDomain.Category] {
        let page = try await repositories.dashboard.page(
            query: TransactionQuery(month: YearMonth(now()), kinds: [.expense]), after: nil,
            limit: 500)
        var counts: [String: Int] = [:]
        for transaction in page.items { counts[transaction.category.id, default: 0] += 1 }
        return try await categories().filter { counts[$0.id] != nil }
            .sorted { counts[$0.id, default: 0] > counts[$1.id, default: 0] }
    }
}
