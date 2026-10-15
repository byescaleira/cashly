import Foundation

public enum ProTenure {
    public static let monthLength: TimeInterval = 30 * 86_400

    public static func months(of periods: [DateInterval]) -> Int {
        var total: TimeInterval = 0
        var open: DateInterval?
        for period in periods.sorted(by: { $0.start < $1.start }) {
            if let current = open, period.start <= current.end {
                open = DateInterval(start: current.start, end: max(current.end, period.end))
            } else {
                total += open?.duration ?? 0
                open = period
            }
        }
        total += open?.duration ?? 0
        return Int(total / monthLength)
    }
}
