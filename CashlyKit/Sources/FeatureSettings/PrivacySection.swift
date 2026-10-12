import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct PrivacySection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(AppLockModel.self) private var lock: AppLockModel?

    var body: some View {
        @Bindable var settings = settings
        Section {
            Group {
                Toggle(lockTitle, isOn: $settings.locksApp)
                Toggle("Discreet Mode", isOn: $settings.isDiscreet)
            }
            .tint(.positive)
        } footer: {
            Text(
                "Locking asks to unlock whenever Cashly comes back to the front and hides the content in the app switcher. Discreet mode blurs every amount until you turn it off."
            )
        }
    }

    private var lockTitle: String {
        let biometry = lock?.biometry ?? .none
        return biometry == .none
            ? String(appLocalized: "Lock with Passcode")
            : String(appLocalized: "Lock with \(biometry.title)")
    }
}
