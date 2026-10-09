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
    public var currency: String {
        didSet {
            defaults.set(currency, forKey: Key.currency)
            currencySetting.code = currency
        }
    }
    public var syncsWithICloud: Bool {
        didSet { defaults.set(syncsWithICloud, forKey: Key.cloudSync) }
    }
    public private(set) var cloudAccount: CloudAccount
    public var data: DataModel?
    public let notifications: NotificationsModel
    public let info: AppInfo
    public let syncsAtLaunch: Bool
    private let cloudContainer: String?
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let currencySetting: CurrencySetting

    public init(
        defaults: UserDefaults = .standard, cloudContainer: String?, info: AppInfo = .main,
        currencySetting: CurrencySetting = .shared,
        notifications: NotificationsModel = NotificationsModel()
    ) {
        self.notifications = notifications
        self.defaults = defaults
        self.cloudContainer = cloudContainer
        self.info = info
        self.currencySetting = currencySetting
        let currency =
            defaults.string(forKey: Key.currency).flatMap {
                CurrencySetting.isSupported($0) ? $0 : nil
            } ?? currencySetting.code
        currencySetting.code = currency
        self.currency = currency
        appearance =
            defaults.string(forKey: Key.appearance).flatMap(Appearance.init(rawValue:)) ?? .system
        let syncs = defaults.object(forKey: Key.cloudSync) as? Bool ?? true
        syncsWithICloud = syncs
        syncsAtLaunch = cloudContainer != nil && syncs
        cloudAccount = cloudContainer == nil ? .unavailable : .checking
    }

    public var isCloudAvailable: Bool { cloudContainer != nil }

    var isSyncOn: Bool {
        get { isCloudAvailable && syncsWithICloud }
        set { syncsWithICloud = newValue }
    }

    var needsRestart: Bool { isCloudAvailable && syncsWithICloud != syncsAtLaunch }

    var cloudFooter: String {
        if !isCloudAvailable { return "A sincronização não está disponível nesta instalação." }
        if needsRestart { return "A mudança vale na próxima vez que o Cashly abrir." }
        if syncsAtLaunch {
            return "Seus dados ficam na sua conta do iCloud e aparecem nos seus outros aparelhos."
        }
        return "Seus dados ficam só neste aparelho."
    }

    func currencyName(_ code: String) -> String {
        let name = Locale(identifier: "pt_BR").localizedString(forCurrencyCode: code) ?? code
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
    }
}
