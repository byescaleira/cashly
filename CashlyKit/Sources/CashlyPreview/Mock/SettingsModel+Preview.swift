import FeatureSettings
import Foundation

extension SettingsModel {
    static var preview: SettingsModel {
        SettingsModel(
            defaults: UserDefaults(suiteName: "cashly.preview") ?? .standard,
            cloudContainer: nil,
            info: AppInfo(info: [
                "CFBundleShortVersionString": "1.0", "CFBundleVersion": "1",
                "CashlyAppStoreID": "0", "CashlySupportEmail": "suporte@cashly.app",
            ]))
    }
}
