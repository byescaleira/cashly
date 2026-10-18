import Foundation

struct TransactionRow: Codable, Equatable {
    var id: String
    var participants: [String]
    var budget: String
    var categoryID: String
    var kind: Int
    var amount: Double
    var dateSource: Double
    var paymentsPlanSource: Int?
    var amountSource: Double
    var amountMinorUnits: Int64?
    var ownerMinorUnits: Int64?
    var currencyCode: String
    var ownerID: String
    var tagIDs: [String]
    var tagsMigrated: Bool
    var startMonthIndex: Int
    var endMonthIndex: Int
    var contentRevision: String
    var date: Double
    var summary: String
    var status: Int
    var splitMode: Int?
    var splitValue: Double?
    var paymentsPlan: Int?
    var paidCurrencyCode: String?
    var paidMinorUnits: Int64?
    var exchangeRate: String?
    var exchangeRateDate: Double?

    init(_ entity: TransactionEntity) {
        id = entity.id
        participants = entity.participants
        budget = entity.budget
        categoryID = entity.categoryID
        kind = entity.kind
        amount = entity.amount
        dateSource = entity.dateSource
        paymentsPlanSource = entity.paymentsPlanSource
        amountSource = entity.amountSource
        amountMinorUnits = entity.amountMinorUnits
        ownerMinorUnits = entity.ownerMinorUnits
        currencyCode = entity.currencyCode
        ownerID = entity.ownerID
        tagIDs = entity.tagIDs
        tagsMigrated = entity.tagsMigrated
        startMonthIndex = entity.startMonthIndex
        endMonthIndex = entity.endMonthIndex
        contentRevision = entity.contentRevision
        date = entity.date
        summary = entity.summary
        status = entity.status
        splitMode = entity.splitMode
        splitValue = entity.splitValue
        paymentsPlan = entity.paymentsPlan
        paidCurrencyCode = entity.paidCurrencyCode
        paidMinorUnits = entity.paidMinorUnits
        exchangeRate = entity.exchangeRate
        exchangeRateDate = entity.exchangeRateDate
    }

    func apply(to entity: TransactionEntity) {
        entity.participants = participants
        entity.budget = budget
        entity.categoryID = categoryID
        entity.kind = kind
        entity.amount = amount
        entity.dateSource = dateSource
        entity.paymentsPlanSource = paymentsPlanSource
        entity.amountSource = amountSource
        entity.amountMinorUnits = amountMinorUnits
        entity.ownerMinorUnits = ownerMinorUnits
        entity.currencyCode = currencyCode
        entity.ownerID = ownerID
        entity.tagIDs = tagIDs
        entity.tagsMigrated = tagsMigrated
        entity.startMonthIndex = startMonthIndex
        entity.endMonthIndex = endMonthIndex
        entity.contentRevision = contentRevision
        entity.date = date
        entity.summary = summary
        entity.status = status
        entity.splitMode = splitMode
        entity.splitValue = splitValue
        entity.paymentsPlan = paymentsPlan
        entity.paidCurrencyCode = paidCurrencyCode
        entity.paidMinorUnits = paidMinorUnits
        entity.exchangeRate = exchangeRate
        entity.exchangeRateDate = exchangeRateDate
    }
}
