import CashlyDomain
import Foundation
import SwiftData

@Model
public class BudgetEntity {
    #Index<BudgetEntity>([\.ownerID, \.date, \.category])
    public var id: String = ""
    public var amount: Double = 0
    public var amountSource: Double = -1
    public var amountMinorUnits: Int64?
    public var currencyCode: String = "BRL"
    public var isConflicted: Bool = false
    public var ownerID: String = ""
    public var mergedIntoID: String = ""
    public var resolutionToken: String = ""
    public var resolutionTimestamp: Double = 0
    public var resolvedTargetID: String = ""
    public var category: String = ""
    public var date: Int = 0
    public var summary: String = ""

    public init(
        id: String,
        amount: Double,
        category: String,
        date: Int,
        summary: String
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.summary = summary
    }
}
