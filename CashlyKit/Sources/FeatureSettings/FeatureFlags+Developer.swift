import CashlyDomain
import FeatureCore

extension FeatureFlags {
    func isOverridden(_ flag: FeatureFlag) -> Bool { overrides[flag.rawValue] != nil }

    var overriddenCount: Int { FeatureFlag.allCases.filter(isOverridden).count }

    var overridesSummary: String {
        String(appLocalized: "\(overriddenCount) flags changed")
    }

    func source(of flag: FeatureFlag) -> String {
        if isOverridden(flag) { return String(appLocalized: "Changed on this device") }
        if let remote = remote[flag.rawValue] {
            return String(appLocalized: "Remote, \(remote.rollout)% rollout")
        }
        return flag.defaultValue
            ? String(appLocalized: "Default: on") : String(appLocalized: "Default: off")
    }

    func restoreDefaults() {
        for flag in FeatureFlag.allCases { override(flag, nil) }
    }
}
