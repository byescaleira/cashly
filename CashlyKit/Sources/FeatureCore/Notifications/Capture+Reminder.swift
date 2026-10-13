import CashlyDomain
import Foundation

extension Capture {
    public func reminder(categories: [CashlyDomain.Category]) -> Reminder {
        let suggested = categories.first { $0.id == suggestedCategoryID }
        let body =
            suggested.map { String(appLocalized: "Suggestion: \($0.name). Tap to classify.") }
            ?? String(appLocalized: "Tap to classify.")
        return Reminder(
            id: "capture.\(id)", title: String(appLocalized: "\(money.formatted) at \(merchant)"),
            body: body, components: DateComponents(),
            category: NotificationCategory.capture(suggesting: suggested?.id),
            userInfo: [NotificationCategory.captureKey: id])
    }
}
