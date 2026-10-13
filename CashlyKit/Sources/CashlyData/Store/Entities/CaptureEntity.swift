import Foundation
import SwiftData

@Model
public class CaptureEntity {
    #Index<CaptureEntity>(
        [\.ownerID, \.id], [\.ownerID, \.status, \.date], [\.ownerID, \.merchantKey, \.minute])
    public var id: String = ""
    public var ownerID: String = ""
    public var amountMinorUnits: Int64 = 0
    public var currencyCode: String = "BRL"
    public var merchant: String = ""
    public var merchantKey: String = ""
    public var card: String = ""
    public var date: TimeInterval = 0
    public var minute: Int64 = 0
    public var source: String = ""
    public var suggestedCategoryID: String = ""
    public var suggestedSummary: String = ""
    public var suggestedTagIDs: [String] = []
    public var status: String = ""
    public var transactionID: String = ""
    public var createdAt: TimeInterval = 0

    public init(id: String, ownerID: String) {
        self.id = id
        self.ownerID = ownerID
    }
}
