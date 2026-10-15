import Foundation

public enum NotificationCategory {
    public static let bill = "cashly.bill"
    public static let budget = "cashly.budget"
    public static let weekly = "cashly.weekly"
    public static let markPaid = "cashly.bill.paid"
    public static let postpone = "cashly.bill.postpone"
    public static let transactionKey = "transactionID"
    public static let capture = "cashly.capture"
    public static let captureOther = "cashly.capture.other"
    public static let captureIgnore = "cashly.capture.ignore"
    public static let capturePick = "cashly.capture.pick."
    public static let captureKey = "captureID"
    public static let journey = "cashly.journey"
    public static let journeyStreak = "cashly.journey.streak"
    public static let journeyNoSpend = "cashly.journey.noSpend"
    public static let journeyExpense = "cashly.journey.expense"
    public static let linkKey = "link"

    public static func capture(suggesting categoryID: String?) -> String {
        categoryID.map { "\(capture).\($0)" } ?? capture
    }
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
