import Foundation

public struct Budget: CashlyEntity, Sendable {
    public var id: String
    public var money: Money
    public var amount: Double { money.doubleValue }
    public var category: Category
    public var date: Int
    public var summary: String
    public var isConflicted: Bool
    public var user: User { category.user }
    public init(
        id: String, money: Money, category: Category, date: Int, summary: String,
        isConflicted: Bool = false
    ) {
        self.id = id
        self.money = money
        self.category = category
        self.date = date
        self.summary = summary
        self.isConflicted = isConflicted
    }
    private enum CodingKeys: String, CodingKey {
        case id, money, amount, category, date, summary, isConflicted
    }
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        money =
            try values.decodeIfPresent(Money.self, forKey: .money)
            ?? Money(validating: values.decode(Double.self, forKey: .amount))
        category = try values.decode(Category.self, forKey: .category)
        date = try values.decode(Int.self, forKey: .date)
        summary = try values.decode(String.self, forKey: .summary)
        isConflicted = try values.decodeIfPresent(Bool.self, forKey: .isConflicted) ?? false
    }
    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(money, forKey: .money)
        try values.encode(category, forKey: .category)
        try values.encode(date, forKey: .date)
        try values.encode(summary, forKey: .summary)
        try values.encode(isConflicted, forKey: .isConflicted)
    }
}
