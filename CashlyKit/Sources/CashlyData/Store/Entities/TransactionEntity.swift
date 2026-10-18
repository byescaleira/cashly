import CashlyDomain
import Foundation
import SwiftData

@Model
public class TransactionEntity {
    #Index<TransactionEntity>(
        [\.ownerID, \.date, \.id], [\.ownerID, \.id], [\.ownerID, \.categoryID, \.date],
        [\.ownerID, \.kind, \.date], [\.ownerID, \.startMonthIndex, \.endMonthIndex])
    public var id: String = ""
    public var participants: [String] = []
    public var budget: String = ""
    public var categoryID: String = ""
    public var kind: Int = 0
    public var amount: Double = 0
    public var dateSource: Double = 0
    public var paymentsPlanSource: Int?
    public var amountSource: Double = -1
    public var amountMinorUnits: Int64?
    public var ownerMinorUnits: Int64?
    public var currencyCode: String = "BRL"
    public var ownerID: String = ""
    public var tagIDs: [String] = []
    public var tagsMigrated: Bool = false
    public var startMonthIndex: Int = 0
    public var endMonthIndex: Int = 0
    public var contentRevision: String = ""
    public var date: TimeInterval = 0
    public var summary: String = ""
    public var status: Int = 0
    public var splitMode: Int?
    public var splitValue: Double?
    public var paymentsPlan: Int?
    public var paidCurrencyCode: String?
    public var paidMinorUnits: Int64?
    public var exchangeRate: String?
    public var exchangeRateDate: Double?

    public init(
        id: String,
        participants: [String],
        budget: String,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int,
        splitMode: Int? = nil,
        splitValue: Double? = nil,
        paymentsPlan: Int? = nil
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
    }
}
