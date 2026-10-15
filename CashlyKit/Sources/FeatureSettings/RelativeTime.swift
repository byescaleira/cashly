import CashlyDomain
import Foundation

enum RelativeTime {
    static func moment(
        _ date: Date, now: Date, context: Formatter.Context = .beginningOfSentence
    ) -> String {
        let interval = date.timeIntervalSince(now)
        return formatter(context).localizedString(
            fromTimeInterval: abs(interval) < 60 ? 0 : interval)
    }

    static func day(
        _ date: Date, now: Date, calendar: Calendar = .current,
        context: Formatter.Context = .beginningOfSentence
    ) -> String {
        let days =
            calendar.dateComponents(
                [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)
            ).day ?? 0
        return formatter(context).localizedString(from: DateComponents(day: days))
    }

    private static func formatter(_ context: Formatter.Context) -> RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = .app
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        formatter.formattingContext = context
        return formatter
    }
}
