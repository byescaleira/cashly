import Foundation
import Observation

@MainActor @Observable
public final class JourneyNotificationSetting {
    public static let shared = JourneyNotificationSetting()
    public nonisolated static let key = "cashly.notifications.journey"
    public nonisolated static let prefix = "journey.plan."
    public private(set) var isOn: Bool
    public private(set) var status: NotificationStatus = .notDetermined
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let scheduler: any NotificationScheduling

    public init(
        defaults: UserDefaults = .standard,
        scheduler: any NotificationScheduling = SystemNotifications()
    ) {
        self.defaults = defaults
        self.scheduler = scheduler
        isOn = Self.isOn(in: defaults)
    }

    public nonisolated static func isOn(in defaults: UserDefaults) -> Bool {
        defaults.object(forKey: key) as? Bool ?? true
    }

    public var toggle: Bool {
        get { isOn }
        set { Task { await set(newValue) } }
    }

    public func refreshStatus() async {
        status = await scheduler.status()
    }

    public func set(_ isOn: Bool) async {
        if isOn {
            if await scheduler.status() == .notDetermined {
                _ = await scheduler.requestAuthorization()
            }
            status = await scheduler.status()
            guard status == .allowed else { return }
        }
        self.isOn = isOn
        defaults.set(isOn, forKey: Self.key)
        if !isOn { await scheduler.replace(prefix: Self.prefix, with: []) }
    }
}
