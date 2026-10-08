import Foundation

public enum CashlyCalendar {
    public static var current: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.locale = .current
        return calendar
    }
}
