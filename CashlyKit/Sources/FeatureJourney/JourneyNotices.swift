import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

public struct JourneyNotices {
    public static let streakHour = 20
    public static let outcomeHour = 9
    public static let missionsHour = 9
    public static let missionsEndHour = 12
    public static let challengeHour = 18
    public static let journeyLink = "cashly://journey"
    public static let restoreLink = "cashly://shop/" + ShopItem.streakRestore.rawValue

    public let progress: GameProgress
    public let userID: String
    public let now: Date
    public let calendar: Calendar

    public init(
        progress: GameProgress, userID: String, now: Date,
        calendar: Calendar = CashlyCalendar.current
    ) {
        self.progress = progress
        self.userID = userID
        self.now = now
        self.calendar = calendar
    }

    public var scheduled: [Reminder] {
        [streakAtRisk, streakOutcome, newMissions, missionsEnding, challengeEnding].compactMap {
            $0
        }
    }

    var today: Date { calendar.startOfDay(for: now) }

    private var streakAtRisk: Reminder? {
        let streak = progress.streak
        guard streak.current > 0 else { return nil }
        let body =
            streak.freezes > 0
            ? String(
                appLocalized:
                    "Record something or mark a no-spend day before midnight. Otherwise a freeze will cover the day."
            )
            : String(
                appLocalized:
                    "Record something or mark a no-spend day before midnight to keep it.")
        return reminder(
            "streak", at: day(streak.isTodayTracked ? 1 : 0, hour: Self.streakHour),
            title: String(appLocalized: "Your \(streak.current)-day streak is at risk"), body: body,
            category: NotificationCategory.journeyStreak)
    }

    private var streakOutcome: Reminder? {
        let streak = progress.streak
        guard streak.current > 0, !streak.isTodayTracked else { return nil }
        let date = day(1, hour: Self.outcomeHour)
        guard streak.freezes > 0 else {
            return reminder(
                "outcome", at: date,
                title: String(appLocalized: "Your \(streak.current)-day streak ended"),
                body: String(
                    appLocalized:
                        "Restore it in the shop within 48 hours, or start a new one today."),
                link: Self.restoreLink)
        }
        return reminder(
            "outcome", at: date, title: String(appLocalized: "A freeze saved your streak"),
            body: String(
                appLocalized:
                    "Yesterday had no activity, so a freeze kept your streak going. Freezes left: \(streak.freezes - 1)."
            ))
    }

    private var newMissions: Reminder? {
        reminder(
            "missions", at: weekEnd.flatMap { at(Self.missionsHour, on: $0) },
            title: String(appLocalized: "New weekly missions"),
            body: String(
                appLocalized: "This week's missions are ready, worth \(Mission.xp) XP each."))
    }

    private var missionsEnding: Reminder? {
        let started = progress.missions.filter { !$0.isCompleted && $0.value > 0 }
        guard let closest = started.max(by: { $0.progress < $1.progress }),
            let end = weekEnd, let last = calendar.date(byAdding: .day, value: -1, to: end)
        else { return nil }
        let kind = closest.kind
        return reminder(
            "missionsEnd", at: at(Self.missionsEndHour, on: last),
            title: String(appLocalized: "Missions end tonight"),
            body: String(
                appLocalized:
                    "\(kind.title): \(closest.value)/\(kind.target). Finish it for +\(Mission.xp) XP before new missions arrive."
            ))
    }

    private var challengeEnding: Reminder? {
        guard let state = progress.challenge, case .active = state.status,
            let eve = calendar.date(byAdding: .day, value: -2, to: state.end)
        else { return nil }
        let kind = state.challenge.kind
        return reminder(
            "challenge", at: at(Self.challengeHour, on: eve),
            title: String(appLocalized: "\(kind.title) ends tomorrow"),
            body: state.caption + " " + String(appLocalized: "One more day for +\(kind.xp) XP."))
    }

    private var weekEnd: Date? {
        var monday = calendar
        monday.firstWeekday = 2
        return monday.dateInterval(of: .weekOfYear, for: today)?.end
    }

    private func day(_ offset: Int, hour: Int) -> Date? {
        calendar.date(byAdding: .day, value: offset, to: today).flatMap { at(hour, on: $0) }
    }

    private func at(_ hour: Int, on date: Date) -> Date? {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)
    }

    private func reminder(
        _ id: String, at date: Date?, title: String, body: String,
        link: String = JourneyNotices.journeyLink, category: String = NotificationCategory.journey
    ) -> Reminder? {
        guard let date, date > now else { return nil }
        return Reminder(
            id: JourneyNotificationSetting.prefix + id, title: title, body: body,
            components: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            category: category, userInfo: [NotificationCategory.linkKey: link])
    }
}
