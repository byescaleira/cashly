import CashlyDomain
import CloudKit
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class SettingsModel {
    public var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }
    public var tint: String {
        didSet { defaults.set(tint, forKey: Key.tint) }
    }
    public var currency: String {
        didSet {
            defaults.set(currency, forKey: Key.currency)
            currencySetting.code = currency
        }
    }
    public var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Key.language)
            if language == .system {
                defaults.removeObject(forKey: Key.systemLanguages)
            } else {
                defaults.set([language.rawValue], forKey: Key.systemLanguages)
            }
            languageSetting.language = language
        }
    }
    public var showsJourney: Bool {
        didSet { defaults.set(showsJourney, forKey: Key.journey) }
    }
    public var syncsWithICloud: Bool {
        didSet { defaults.set(syncsWithICloud, forKey: Key.cloudSync) }
    }
    public private(set) var cloudAccount: CloudAccount
    public private(set) var lastSync: Date?
    public private(set) var appIcon: AppIcon
    public var iconError: String?
    public var data: DataModel?
    public var developer: DeveloperModel?
    public let notifications: NotificationsModel
    public let info: AppInfo
    public let syncsAtLaunch: Bool
    private let cloudContainer: String?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let currencySetting: CurrencySetting
    @ObservationIgnored private let languageSetting: LanguageSetting
    @ObservationIgnored private let iconSwitcher: any AppIconSwitching

    public init(
        defaults: UserDefaults = .standard, cloudContainer: String?, info: AppInfo = .main,
        currencySetting: CurrencySetting = .shared, languageSetting: LanguageSetting = .shared,
        notifications: NotificationsModel = NotificationsModel(),
        iconSwitcher: any AppIconSwitching = SystemAppIcon()
    ) {
        self.iconSwitcher = iconSwitcher
        lastSync = defaults.object(forKey: Key.lastSync) as? Date
        appIcon = AppIcon(assetName: iconSwitcher.current)
        self.notifications = notifications
        self.defaults = defaults
        self.cloudContainer = cloudContainer
        self.info = info
        self.currencySetting = currencySetting
        self.languageSetting = languageSetting
        let language =
            defaults.string(forKey: Key.language).flatMap(AppLanguage.init(rawValue:)) ?? .system
        languageSetting.language = language
        self.language = language
        let currency =
            defaults.string(forKey: Key.currency).flatMap {
                CurrencySetting.isSupported($0) ? $0 : nil
            } ?? currencySetting.code
        currencySetting.code = currency
        self.currency = currency
        appearance =
            defaults.string(forKey: Key.appearance).flatMap(Appearance.init(rawValue:)) ?? .system
        tint = defaults.string(forKey: Key.tint) ?? RetroColor.default.hex
        showsJourney = defaults.object(forKey: Key.journey) as? Bool ?? true
        let syncs = defaults.object(forKey: Key.cloudSync) as? Bool ?? true
        syncsWithICloud = syncs
        syncsAtLaunch = cloudContainer != nil && syncs
        cloudAccount = cloudContainer == nil ? .unavailable : .checking
    }

    public var locale: Locale { languageSetting.locale }

    public var isCloudAvailable: Bool { cloudContainer != nil }

    var cloudContainerName: String {
        cloudContainer ?? String(appLocalized: "Off in this installation")
    }

    var isSyncOn: Bool {
        get { isCloudAvailable && syncsWithICloud }
        set { syncsWithICloud = newValue }
    }

    var needsRestart: Bool { isCloudAvailable && syncsWithICloud != syncsAtLaunch }

    var cloudFooter: String {
        if !isCloudAvailable {
            return String(appLocalized: "Sync isn't available in this installation.")
        }
        if needsRestart {
            return String(appLocalized: "The change applies the next time Cashly opens.")
        }
        if syncsAtLaunch {
            return String(
                appLocalized:
                    "Your data stays in your iCloud account and shows up on your other devices.")
        }
        return String(appLocalized: "Your data stays on this device only.")
    }

    public func recordSync(_ date: Date) {
        guard date > lastSync ?? .distantPast else { return }
        lastSync = date
        defaults.set(date, forKey: Key.lastSync)
    }

    var lastSyncText: String {
        lastSync?.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, locale: .app))
            ?? String(appLocalized: "Not yet")
    }

    var supportsAppIcons: Bool { iconSwitcher.supportsAlternateIcons }

    var isShowingIconError: Bool {
        get { iconError != nil }
        set { if !newValue { iconError = nil } }
    }

    func setAppIcon(_ icon: AppIcon) async {
        guard icon != appIcon else { return }
        do {
            try await iconSwitcher.set(icon.assetName)
            appIcon = icon
        } catch {
            iconError = String(appLocalized: "Couldn't change the icon.")
        }
    }

    func currencyName(_ code: String) -> String {
        let name = Locale.app.localizedString(forCurrencyCode: code) ?? code
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    func loadCloudAccount() async {
        guard let cloudContainer else { return }
        cloudAccount = .checking
        do {
            cloudAccount = CloudAccount(
                try await CKContainer(identifier: cloudContainer).accountStatus())
        } catch {
            cloudAccount = .unavailable
        }
    }

    private enum Key {
        static let appearance = "cashly.settings.appearance"
        static let cloudSync = "cashly.settings.cloudSync"
        static let currency = "cashly.settings.currency"
        static let language = "cashly.settings.language"
        static let journey = "cashly.settings.journey"
        static let systemLanguages = "AppleLanguages"
        static let lastSync = "cashly.settings.lastSync"
        static let tint = "cashly.settings.tint"
    }
}
