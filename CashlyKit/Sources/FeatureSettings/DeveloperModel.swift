import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class DeveloperModel {
    public static let testNotificationDelay: TimeInterval = 5

    public private(set) var isWorking = false
    public var message: String?
    public var error: CashlyError?
    public var isConfirmingReset = false
    let storeURL: URL?
    let bundleID: String
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let scheduler: any NotificationScheduling
    @ObservationIgnored private let sample: (@Sendable () async throws -> Void)?

    public init(
        storeURL: URL?, bundleID: String = Bundle.main.bundleIdentifier ?? "—",
        defaults: UserDefaults = .standard,
        scheduler: any NotificationScheduling = SystemNotifications(),
        sample: (@Sendable () async throws -> Void)? = nil
    ) {
        self.storeURL = storeURL
        self.bundleID = bundleID
        self.defaults = defaults
        self.scheduler = scheduler
        self.sample = sample
    }

    var hasSample: Bool { sample != nil }

    var storePath: String {
        storeURL?.path(percentEncoded: false) ?? String(appLocalized: "In memory")
    }

    var isShowingMessage: Bool {
        get { message != nil }
        set { if !newValue { message = nil } }
    }

    var preferenceKeys: [String] {
        defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(Self.prefix) }.sorted()
    }

    func loadSample() async {
        guard let sample else { return }
        await perform {
            try await sample()
            message = String(appLocalized: "Sample data loaded.")
        }
    }

    func sendTestNotification(now: Date = .now) async {
        if await scheduler.status() == .notDetermined {
            _ = await scheduler.requestAuthorization()
        }
        guard await scheduler.status() == .allowed else {
            message = String(
                appLocalized: "Cashly notifications are turned off in system settings.")
            return
        }
        let date = now.addingTimeInterval(Self.testNotificationDelay)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date)
        let reminder = Reminder(
            id: Self.testNotification, title: String(appLocalized: "Test notification"),
            body: String(appLocalized: "If you're reading this, Cashly notifications work."),
            components: components)
        await scheduler.replace(prefix: Self.testNotification, with: [reminder])
        message = String(
            appLocalized: "The notification arrives in a few seconds. Leave the app to see it.")
    }

    func resetPreferences() {
        for key in preferenceKeys { defaults.removeObject(forKey: key) }
        message = String(
            appLocalized: "Preferences deleted. Close and reopen Cashly to start from scratch.")
    }

    private static let prefix = "cashly."
    private static let testNotification = "developer.test"

    private func perform(_ operation: () async throws -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do { try await operation() } catch {
            self.error = error as? CashlyError ?? .onSave
        }
    }
}
