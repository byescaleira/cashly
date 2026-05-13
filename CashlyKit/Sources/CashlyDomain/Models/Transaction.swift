//
//  Transaction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import Foundation

public struct Transaction: CashlyEntity, Sendable {
    public var id: String
    public var participants: [Participant]
    public var budget: Budget
    public var amount: Double
    public var date: TimeInterval
    public var summary: String
    public var status: TransactionStatus
    public var splitMode: TransactionSplitMode?
    public var splitValue: Double?
    public var paymentsPlan: Int?
    /// Direction of the money flow. Defaults to ``TransactionKind/expense``
    /// so existing callsites keep their pre-J2 behavior.
    public var kind: TransactionKind
    /// `true` when the transaction was captured from dictation (J8+)
    /// and one or more fields could not be inferred. UI surfaces a
    /// badge until the user reviews + flips this back to `false`.
    public var needsReview: Bool
    /// Direct category reference. Introduced in J2d as the migration
    /// target away from the Budget FK (ADR-0009). Optional during
    /// the coexistence window; once J2f drops `budget`, this
    /// becomes the only category source and turns non-optional.
    public var category: CashlyDomain.Category?

    public init(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?,
        kind: TransactionKind = .expense,
        needsReview: Bool = false,
        category: CashlyDomain.Category? = nil
    ) {
        self.id = id
        self.participants = participants
        self.budget = budget
        self.amount = amount
        self.date = date
        self.summary = summary
        self.status = status
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.paymentsPlan = paymentsPlan
        self.kind = kind
        self.needsReview = needsReview
        // Falls back to the budget's category so every existing
        // callsite gets a non-nil category without code changes.
        self.category = category ?? budget.category
    }
}

public extension Transaction {
    /// Effective category — uses the direct `category` reference
    /// when present, otherwise falls back to `budget.category`.
    /// Pre-J2d callsites should read this; once J2f lands and
    /// `category` is non-optional, callsites can use it directly.
    var effectiveCategory: CashlyDomain.Category {
        category ?? budget.category
    }
}

extension Transaction: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, participants, budget, amount, date, summary, status
        case splitMode, splitValue, paymentsPlan, kind, needsReview, category
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.participants = try c.decode([Participant].self, forKey: .participants)
        self.budget = try c.decode(Budget.self, forKey: .budget)
        self.amount = try c.decode(Double.self, forKey: .amount)
        self.date = try c.decode(TimeInterval.self, forKey: .date)
        self.summary = try c.decode(String.self, forKey: .summary)
        self.status = try c.decode(TransactionStatus.self, forKey: .status)
        self.splitMode = try c.decodeIfPresent(TransactionSplitMode.self, forKey: .splitMode)
        self.splitValue = try c.decodeIfPresent(Double.self, forKey: .splitValue)
        self.paymentsPlan = try c.decodeIfPresent(Int.self, forKey: .paymentsPlan)
        self.kind = try c.decodeIfPresent(TransactionKind.self, forKey: .kind) ?? .expense
        self.needsReview = try c.decodeIfPresent(Bool.self, forKey: .needsReview) ?? false
        let decodedCategory = try c.decodeIfPresent(CashlyDomain.Category.self, forKey: .category)
        self.category = decodedCategory ?? self.budget.category
    }
}

public extension Transaction {
    /// Whether this transaction currently counts toward expense
    /// aggregates. Implements the loan lifecycle rule from ADR-0009:
    /// expense always counts, income never counts, loan counts only
    /// while it remains pending.
    var contributesToExpenseTotals: Bool {
        switch kind {
        case .expense: return true
        case .income: return false
        case .loan:
            switch status {
            case .pendingToPay, .pendingToReceive: return true
            case .settled, .canceled: return false
            }
        }
    }
}

/// Lifecycle status of a transaction (or per-participant share).
///
/// `pendingToReceive` / `pendingToPay` form a directional pair —
/// ``reverse`` swaps them. `settled` / `canceled` are terminal:
/// ``reverse`` returns the same value.
public enum TransactionStatus: Int, CaseIterable, CashlyEntity, Sendable {
    case pendingToReceive = 3
    case pendingToPay = 2
    case settled = 0
    case canceled = 1

    public var id: Int {
        rawValue
    }

    public var summary: String {
        switch self {
        case .pendingToReceive: return "Pending to Receive"
        case .pendingToPay: return "Pending to Pay"
        case .settled: return "Settled"
        case .canceled: return "Canceled"
        }
    }

    public var icon: String {
        switch self {
        case .pendingToReceive: return "arrow.down"
        case .pendingToPay: return "arrow.up"
        case .settled: return "checkmark"
        case .canceled: return "xmark"
        }
    }

    public var reverse: TransactionStatus {
        switch self {
        case .pendingToReceive: return .pendingToPay
        case .pendingToPay: return .pendingToReceive
        case .settled: return .settled
        case .canceled: return .canceled
        }
    }
}

/// How a transaction's amount is split among participants. See
/// ``value(splitValue:amount:)`` for the per-mode arithmetic.
public enum TransactionSplitMode: Int, CaseIterable, CashlyEntity, Sendable {
    /// Divide `amount` evenly across `splitValue` participants.
    case equal = 0
    /// Each participant owes a fixed amount equal to `splitValue`.
    case fixedAmount = 1
    /// Each participant owes `amount * splitValue` (0–1 range).
    case percentage = 2
    /// One participant pays the full amount; others are tracked as
    /// owing 0.
    case payerBased = 3

    public var id: Int { rawValue }

    public var summary: String {
        switch self {
        case .equal:
            return "Equal"
        case .fixedAmount:
            return "Fixed Amount"
        case .percentage:
            return "Percentage"
        case .payerBased:
            return "Payer Based"
        }
    }

    public var description: String {
        switch self {
        case .equal:
            return "Split the total equally among all participants."
        case .fixedAmount:
            return "Assign a fixed amount to each participant."
        case .percentage:
            return "Distribute the total based on percentages."
        case .payerBased:
            return "One participant pays the full amount, others are marked as owing."
        }
    }

    public func value(splitValue: Double?, amount: Double) -> Double? {
        guard let splitValue else { return nil }
        switch self {
        case .equal:
            if splitValue > .zero {
                return amount / splitValue
            }
        case .fixedAmount:
            return splitValue
        case .percentage:
            return amount * splitValue
        case .payerBased:
            return .zero
        }

        return nil
    }
}

public extension Transaction {
    func participantsAmount(filter participants: Set<User>) -> Double {
        if participants.isEmpty {
            if !self.participants.isEmpty {
                return splitValue ?? .zero
            }
            if let plan = paymentsPlan {
                return amount / Double(plan)
            }
            return amount
        }
        let filtered = self.participants.filter { participants.contains($0.user) }
        return filtered.reduce(Double.zero) { acc, participant in
            acc + (participant.splitMode.value(splitValue: participant.splitValue, amount: amount) ?? .zero)
        }
    }
}

public extension Set where Element == Transaction {
    func shareMessage(participants: Set<User>) -> String {
        let transactions = self.sorted { $0.date < $1.date }

        let totalAmount = transactions.reduce(Double.zero) { partial, transaction in
            partial + transaction.participantsAmount(filter: participants)
        }

        var messages = "💸 Expenses Summary ".breakLine.breakLine

        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
        messages += transactions.map { transaction in
            let date = dateFormatter.string(from: Date(timeIntervalSince1970: transaction.date))
            let amount = transaction.participantsAmount(filter: participants)
            let category = transaction.budget.category.name.capitalized
            var message = " 💵 \(amount.currency() ?? "")".breakLine
            message += " 🗓 \(date)".breakLine
            message += " 🏷️ \(category)".space + "-".space + transaction.summary.breakLine
            return message
        }.joined(separator: "\n").breakLine

        messages += "📊 Transactions: \(transactions.count)\n"
        messages += "💰 Total: \(totalAmount.currency() ?? "")"
        return messages
    }
}
