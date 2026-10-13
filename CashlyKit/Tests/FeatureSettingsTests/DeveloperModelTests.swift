import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureSettings

private actor FakeScheduler: NotificationScheduling {
    var current: NotificationStatus
    var scheduled: [String: [Reminder]] = [:]

    init(status: NotificationStatus) {
        current = status
    }

    func status() -> NotificationStatus { current }

    func requestAuthorization() -> Bool {
        current = .allowed
        return true
    }

    func replace(prefix: String, with reminders: [Reminder]) {
        scheduled[prefix] = reminders
    }

    func deliver(_ reminder: Reminder) {}

    func registerCaptureActions(_ groups: [CaptureActionGroup]) {}

    func setBadge(_ count: Int) {}
}

private actor Counter {
    var value = 0

    func increment() { value += 1 }
}

@MainActor
struct DeveloperModelTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard

    @Test func testNotificationArrivesSecondsLater() async throws {
        let scheduler = FakeScheduler(status: .notDetermined)
        let developer = DeveloperModel(
            storeURL: nil, defaults: defaults, scheduler: scheduler)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        await developer.sendTestNotification(now: now)
        let reminder = try #require(await scheduler.scheduled["developer.test"]?.first)
        let date = try #require(Calendar.current.date(from: reminder.components))
        #expect(date == now.addingTimeInterval(DeveloperModel.testNotificationDelay))
        #expect(!reminder.repeats)
        #expect(developer.message?.hasPrefix("The notification arrives") == true)
    }

    @Test func deniedNotificationsExplainWhy() async {
        let scheduler = FakeScheduler(status: .denied)
        let developer = DeveloperModel(storeURL: nil, defaults: defaults, scheduler: scheduler)
        await developer.sendTestNotification()
        #expect(await scheduler.scheduled.isEmpty)
        #expect(developer.message?.contains("turned off") == true)
    }

    @Test func resetPreferencesKeepsOtherKeys() {
        defaults.set(true, forKey: "cashly.data.autoBackup")
        defaults.set("dark", forKey: "cashly.settings.appearance")
        defaults.set(1, forKey: "outro.valor")
        let developer = DeveloperModel(storeURL: nil, defaults: defaults)
        #expect(developer.preferenceKeys.count == 2)
        developer.resetPreferences()
        #expect(developer.preferenceKeys.isEmpty)
        #expect(defaults.integer(forKey: "outro.valor") == 1)
    }

    @Test func sampleDataRunsOnce() async {
        let counter = Counter()
        let developer = DeveloperModel(storeURL: nil, defaults: defaults) {
            await counter.increment()
        }
        #expect(developer.hasSample)
        await developer.loadSample()
        #expect(await counter.value == 1)
        #expect(developer.message == "Sample data loaded.")
        #expect(DeveloperModel(storeURL: nil, defaults: defaults).storePath == "In memory")
    }
}
