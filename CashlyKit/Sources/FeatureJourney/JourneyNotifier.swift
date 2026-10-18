import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation

@MainActor
public struct JourneyNotifier {
    private let scheduler: any NotificationScheduling
    private let defaults: UserDefaults

    public init(
        scheduler: any NotificationScheduling = SystemNotifications(),
        defaults: UserDefaults = .standard
    ) {
        self.scheduler = scheduler
        self.defaults = defaults
    }

    public func review(repositories: Repositories, isActive: Bool, now: Date = .now) async {
        guard let userID = repositories.userID,
            let progress = await progress(repositories, now: now)
        else { return }
        await review(progress, userID: userID, isActive: isActive, now: now)
    }

    public func review(
        _ progress: GameProgress, userID: String, isActive: Bool, now: Date = .now
    ) async {
        let notices = JourneyNotices(progress: progress, userID: userID, now: now)
        let baselineKey = Key.baseline + userID
        let fresh = notices.immediate(
            since: JourneyBaseline(defaults.dictionary(forKey: baselineKey))
        ).filter { !defaults.bool(forKey: Key.sent + $0.id) }
        defaults.set(notices.baseline.dictionary, forKey: baselineKey)
        for reminder in fresh { defaults.set(true, forKey: Key.sent + reminder.id) }
        guard isActive, JourneyNotificationSetting.isOn(in: defaults),
            await scheduler.status() == .allowed
        else {
            await scheduler.replace(prefix: JourneyNotificationSetting.prefix, with: [])
            return
        }
        for reminder in fresh { await scheduler.deliver(reminder) }
        await scheduler.replace(prefix: JourneyNotificationSetting.prefix, with: notices.scheduled)
    }

    public func markNoSpendDay(repositories: Repositories, now: Date = .now) async {
        guard let progress = await progress(repositories, now: now),
            !progress.streak.isTodayTracked
        else { return }
        do {
            try await repositories.game.record([GameEvent(kind: .noSpendDay, date: now)])
        } catch {
            return
        }
        await review(repositories: repositories, isActive: true, now: now)
    }

    private func progress(_ repositories: Repositories, now: Date) async -> GameProgress? {
        let source = RepositoriesGameSource(
            repositories: repositories, guides: Guide.journeyIDs)
        return (try? await source.snapshot(today: now)).map(GameEngine.progress)
    }

    private enum Key {
        static let baseline = "cashly.notifications.journey.baseline."
        static let sent = "cashly.notifications.journey.sent."
    }
}
