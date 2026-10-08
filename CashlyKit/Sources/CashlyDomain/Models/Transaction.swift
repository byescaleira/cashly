import Foundation

public struct Transaction: CashlyEntity, Sendable {
    public var id: String
    public var participants: [Participant]
    public var ownerID: String
    public var category: Category
    public var kind: TransactionKind
    public var money: Money
    public var amount: Double { money.doubleValue }
    public var ownerMoney: Money?
    public var tagIDs: Set<String>
    public var billingStartMonth: Int?
    public var date: TimeInterval
    public var summary: String
    public var status: TransactionStatus
    public var splitMode: TransactionSplitMode?
    public var splitValue: Double?
    public var paymentsPlan: Int?
    public init(
        id: String, participants: [Participant], category: Category, money: Money,
        date: TimeInterval,
        summary: String, status: TransactionStatus, splitMode: TransactionSplitMode?,
        splitValue: Double?, paymentsPlan: Int?, ownerMoney: Money? = nil, tagIDs: Set<String> = [],
        billingStartMonth: Int? = nil, kind: TransactionKind = .expense
    ) {
        self.id = id
        self.participants = participants
        self.ownerID = category.user.id
        self.category = category
        self.kind = kind
        self.money = money
        self.date = date
        self.summary = summary
        self.status = status
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.paymentsPlan = paymentsPlan
        self.ownerMoney = ownerMoney
        self.tagIDs = tagIDs
        self.billingStartMonth = billingStartMonth
    }
    private enum CodingKeys: String, CodingKey {
        case id, participants, ownerID, category, kind, money, amount, ownerMoney, tagIDs,
            billingStartMonth, date,
            summary, status, splitMode, splitValue, paymentsPlan
    }
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        participants = try values.decode([Participant].self, forKey: .participants)
        category = try values.decode(Category.self, forKey: .category)
        ownerID = try values.decodeIfPresent(String.self, forKey: .ownerID) ?? category.user.id
        kind = try values.decodeIfPresent(TransactionKind.self, forKey: .kind) ?? .expense
        money =
            try values.decodeIfPresent(Money.self, forKey: .money)
            ?? Money(validating: values.decode(Double.self, forKey: .amount))
        ownerMoney = try values.decodeIfPresent(Money.self, forKey: .ownerMoney)
        tagIDs = try values.decodeIfPresent(Set<String>.self, forKey: .tagIDs) ?? []
        billingStartMonth = try values.decodeIfPresent(Int.self, forKey: .billingStartMonth)
        date = try values.decode(TimeInterval.self, forKey: .date)
        summary = try values.decode(String.self, forKey: .summary)
        status = try values.decode(TransactionStatus.self, forKey: .status)
        splitMode = try values.decodeIfPresent(TransactionSplitMode.self, forKey: .splitMode)
        splitValue = try values.decodeIfPresent(Double.self, forKey: .splitValue)
        paymentsPlan = try values.decodeIfPresent(Int.self, forKey: .paymentsPlan)
    }
    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(participants, forKey: .participants)
        try values.encode(ownerID, forKey: .ownerID)
        try values.encode(category, forKey: .category)
        try values.encode(kind, forKey: .kind)
        try values.encode(money, forKey: .money)
        try values.encodeIfPresent(ownerMoney, forKey: .ownerMoney)
        try values.encode(tagIDs, forKey: .tagIDs)
        try values.encodeIfPresent(billingStartMonth, forKey: .billingStartMonth)
        try values.encode(date, forKey: .date)
        try values.encode(summary, forKey: .summary)
        try values.encode(status, forKey: .status)
        try values.encodeIfPresent(splitMode, forKey: .splitMode)
        try values.encodeIfPresent(splitValue, forKey: .splitValue)
        try values.encodeIfPresent(paymentsPlan, forKey: .paymentsPlan)
    }
}

public enum TransactionKind: Int, Codable, Hashable, CaseIterable, Identifiable, Sendable {
    case expense = 0
    case income = 1

    public var id: Int { rawValue }
    public var title: String { self == .income ? "Entrada" : "Saída" }
    public var icon: String { self == .income ? "arrow.down.left" : "arrow.up.right" }
}

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

public enum TransactionSplitMode: Int, CaseIterable, CashlyEntity, Sendable {
    case equal = 0
    case fixedAmount = 1
    case percentage = 2
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

extension Set where Element == Transaction {
    public func shareMessage(participants: Set<User>, billingMonth: Int? = nil) -> String {
        let ids = Set<String>(participants.map(\.id))
        let transactions = self.filter { ids.isEmpty || $0.kind == .expense }.sorted(
            by: \.date, using: <)
        func share(_ transaction: Transaction) throws -> Money {
            guard !ids.isEmpty else { return transaction.billingMoney(in: billingMonth) }
            return try transaction.participants.filter { ids.contains($0.user.id) }.reduce(.zero) {
                try $0.adding(transaction.participantMoney(id: $1.id, in: billingMonth))
            }
        }
        do {
            let expenses = try transactions.filter { $0.kind == .expense }.reduce(Money.zero) {
                try $0.adding(share($1))
            }
            let income = try transactions.filter { $0.kind == .income }.reduce(Money.zero) {
                try $0.adding(share($1))
            }
            let net = try income.subtracting(expenses)
            let lines = try transactions.map { transaction in
                let date =
                    (billingMonth.flatMap { transaction.billingDate(in: $0) }
                    ?? transaction.date.date)
                    .string(with: .shareMessage) ?? ""
                return
                    " \(transaction.kind.title): \(try share(transaction).formatted)\n 🗓 \(date)\n 🏷️ \(transaction.category.name.capitalized) - \(transaction.summary)\n"
            }.joined(separator: "\n")
            return "💸 Resumo financeiro\n\n" + lines
                + "\n📊 Registros: \(transactions.count)\nEntradas: \(income.formatted)\nSaídas: \(expenses.formatted)\nResultado: \(net.formatted)"
        } catch {
            return
                "Não foi possível gerar o resumo: o total excede o intervalo monetário permitido."
        }
    }
}

extension Transaction {
    public func billingDate(in yearMonth: Int) -> Date? {
        guard occurs(in: yearMonth) else { return nil }
        let calendar = CashlyCalendar.current
        let original = calendar.dateComponents([.day, .hour, .minute, .second], from: date.date)
        var start = DateComponents(year: yearMonth / 100, month: yearMonth % 100, day: 1)
        guard let first = calendar.date(from: start),
            let days = calendar.range(of: .day, in: .month, for: first)
        else { return nil }
        start.day = min(original.day ?? 1, days.count)
        start.hour = original.hour
        start.minute = original.minute
        start.second = original.second
        return calendar.date(from: start)
    }
    public var attributedMoney: Money {
        guard status != .canceled else { return .zero }
        return ownerMoney
            ?? (try? TransactionAllocation.resolve(total: money, participants: participants).owner)
            ?? .zero
    }
    public var attributedAmount: Double { attributedMoney.doubleValue }
    public var effectiveAmount: Double {
        attributedMoney.installment(at: 0, count: max(paymentsPlan ?? 1, 1)).doubleValue
    }
    public func billingMoney(in month: Int?) -> Money {
        guard let month else { return attributedMoney }
        guard occurs(in: month) else { return .zero }
        let start = billingStartMonth ?? date.yearMonth
        let index = (month / 100 - start / 100) * 12 + month % 100 - start % 100
        return attributedMoney.installment(at: index, count: max(paymentsPlan ?? 1, 1))
    }
    public func participantMoney(id: String, in month: Int? = nil) -> Money {
        guard status != .canceled, let participant = participants.first(where: { $0.id == id })
        else {
            return .zero
        }
        let value =
            participant.allocatedMoney
            ?? (try? TransactionAllocation.resolve(total: money, participants: participants)
                .participants[
                    id]) ?? .zero
        guard let month else { return value }
        guard occurs(in: month) else { return .zero }
        let start = billingStartMonth ?? date.yearMonth
        let index = (month / 100 - start / 100) * 12 + month % 100 - start % 100
        return value.installment(at: index, count: max(paymentsPlan ?? 1, 1))
    }
    public func occurs(in yearMonth: Int) -> Bool {
        guard (1...12).contains(yearMonth % 100), yearMonth / 100 > 0, date.isFinite else {
            return false
        }
        guard let paymentsPlan else { return (billingStartMonth ?? date.yearMonth) == yearMonth }
        guard (1...1200).contains(paymentsPlan) else { return false }
        let start = billingStartMonth ?? date.yearMonth
        let offset = (yearMonth / 100 - start / 100) * 12 + yearMonth % 100 - start % 100
        return offset >= 0 && offset < paymentsPlan
    }
}
