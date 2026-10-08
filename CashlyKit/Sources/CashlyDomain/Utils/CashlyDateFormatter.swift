import Foundation

public enum CashlyDateFormatter: Sendable {
    case weekDay
    case sortPattern
    case defaultFormat
    case transactionSection
    case time
    case yearMonth
    case status
    case year
    case month
    case numberMonth
    case shareMessage

    public var rawValue: DateFormatter {
        switch self {
        case .weekDay: return formatter("EEEE")
        case .defaultFormat: return formatter("dd/MM/yyyy")
        case .sortPattern: return formatter("yyyyMMdd")
        case .transactionSection: return formatter("dd MMMM, yyyy")
        case .time: return formatter("HH:mm")
        case .yearMonth: return formatter("yyyyMM")
        case .status: return formatter("MMMM, yyyy")
        case .year: return formatter("yyyy")
        case .month: return formatter("MMMM")
        case .numberMonth: return formatter("MM")
        case .shareMessage: return formatter("dd MMMM, yyyy | HH:mm")
        }
    }
}

private func formatter(_ pattern: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale =
        pattern == "yyyyMM" || pattern == "yyyyMMdd" ? Locale(identifier: "en_US_POSIX") : .current
    formatter.calendar = CashlyCalendar.current
    formatter.dateFormat = pattern
    return formatter
}
extension CashlyDateFormatter {
    public static func cashly(_ formatter: Self) -> Self { formatter }
    public static func transaction(_ formatter: Self) -> Self { formatter }
}
