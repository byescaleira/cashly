import Foundation

public enum NotificationCategory {
    public static let bill = "cashly.bill"
    public static let budget = "cashly.budget"
    public static let weekly = "cashly.weekly"
    public static let markPaid = "cashly.bill.paid"
    public static let postpone = "cashly.bill.postpone"
    public static let transactionKey = "transactionID"
}

public struct Reminder: Hashable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let components: DateComponents
    public let repeats: Bool
    public let category: String
    public let userInfo: [String: String]
    public let isTimeSensitive: Bool

    public init(
        id: String, title: String, body: String, components: DateComponents, repeats: Bool = false,
        category: String = "", userInfo: [String: String] = [:], isTimeSensitive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.components = components
        self.repeats = repeats
        self.category = category
        self.userInfo = userInfo
        self.isTimeSensitive = isTimeSensitive
    }
}
