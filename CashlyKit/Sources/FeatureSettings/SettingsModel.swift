import CloudKit
import Foundation
import Observation

@MainActor @Observable
public final class SettingsModel {
    public var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }
    public var syncsWithICloud: Bool {
        didSet { defaults.set(syncsWithICloud, forKey: Key.cloudSync) }
    }
    public private(set) var cloudAccount: CloudAccount
    public var data: DataModel?
    public let info: AppInfo
    public let syncsAtLaunch: Bool
    private let cloudContainer: String?
    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard, cloudContainer: String?, info: AppInfo = .main)
    {
        self.defaults = defaults
        self.cloudContainer = cloudContainer
        self.info = info
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
    }
}
