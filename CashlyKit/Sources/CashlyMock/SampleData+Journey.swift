import CashlyDomain
import Foundation

extension SampleData {
    public static func gameEvents(today: Date = .now) -> [GameEvent] {
        let calendar = CashlyCalendar.current
        let start = calendar.startOfDay(for: today)
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .hour, value: 20, to: start.adding(days: offset, calendar))
                ?? start
        }
        let current = (1...11).filter { $0 != 5 }.map { offset in
            GameEvent(id: "sample-nospend-\(offset)", kind: .noSpendDay, date: day(-offset))
        }
        let earlier = (25...42).map { offset in
            GameEvent(id: "sample-nospend-\(offset)", kind: .noSpendDay, date: day(-offset))
        }
        let guides = ["tour", "recording", "budgets"].map { guide in
            GameEvent(
                id: "sample-guide-" + guide, kind: .guideCompleted, date: day(-30), value: guide)
        }
        let restaurants = categories[1].id
        return current + earlier + guides + [
            GameEvent(
                id: "sample-freezes", kind: .freezesCredited, date: day(-15), value: "sample",
                count: 2),
            GameEvent(
                id: "sample-challenge-done", kind: .challengeStarted, date: day(-41),
                value: "trackWeek||"),
            GameEvent(
                id: "sample-challenge-missed", kind: .challengeStarted, date: day(-24),
                value: "everyDay||"),
            GameEvent(
                id: "sample-challenge", kind: .challengeStarted, date: day(-3),
                value: "cap|\(restaurants)|60000"),
        ]
    }
}

extension Date {
    fileprivate func adding(days: Int, _ calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }
}
