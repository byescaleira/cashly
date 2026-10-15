import Foundation

extension ReminderText {
    public static func streakAtRisk(days: Int) -> ReminderText {
        ReminderText(
            title: String(appLocalized: "Your \(days)-day streak is at risk"),
            body: String(
                appLocalized:
                    "Record something or mark a no-spend day before midnight. Otherwise a freeze will cover the day."
            ))
    }
}
