import CashlyDomain
import FeatureCore
import Foundation

struct PrivacySampleRow: Identifiable, Equatable {
    let symbol: String
    let title: String
    let color: RetroColor
    let amount: String

    var id: String { symbol }
}

extension SettingsModel {
    func lockTitle(_ biometry: BiometryKind) -> String {
        biometry == .none
            ? String(appLocalized: "Lock with Passcode")
            : String(appLocalized: "Lock with \(biometry.title)")
    }

    func lockSymbol(_ biometry: BiometryKind) -> String {
        switch biometry {
        case .none: "lock"
        case .touchID: "touchid"
        case .faceID: "faceid"
        case .opticID: "opticid"
        }
    }

    func privacyHeadline(_ biometry: BiometryKind) -> String {
        guard locksApp else { return String(appLocalized: "Cashly opens without a lock") }
        return biometry == .none
            ? String(appLocalized: "Protected with your passcode")
            : String(appLocalized: "Protected with \(biometry.title)")
    }

    var lockDetail: String {
        String(
            appLocalized:
                "Asks to unlock when Cashly comes back and hides it in the app switcher.")
    }

    var privacyDetail: String {
        isDiscreet
            ? String(appLocalized: "Amounts stay blurred until you turn discreet mode off.")
            : String(appLocalized: "Amounts are visible on every screen.")
    }

    func privacyValue(_ biometry: BiometryKind) -> String {
        switch (locksApp, isDiscreet) {
        case (true, true): String(appLocalized: "\(biometry.title) · Discreet")
        case (true, false): biometry.title
        case (false, true): String(appLocalized: "Discreet")
        case (false, false): String(appLocalized: "Off")
        }
    }

    var privacySample: [PrivacySampleRow] {
        [
            PrivacySampleRow(
                symbol: "cart", title: String(appLocalized: "Groceries"), color: .olive,
                amount: Money(minorUnits: -32_090).formatted),
            PrivacySampleRow(
                symbol: "cup.and.saucer", title: String(appLocalized: "Coffee"), color: .coffee,
                amount: Money(minorUnits: -1_250).formatted),
        ]
    }

    var privacySampleBalance: String { Money(minorUnits: 184_250).formatted }
}
