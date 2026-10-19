import CashlyDomain
import FeatureCore
import Foundation

extension AppUpdateModel {
    var simulation: UpdateState? {
        get { cache.simulated }
        set { simulate(newValue) }
    }

    var installedValue: String {
        installed?.description ?? String(appLocalized: "Unknown")
    }

    var policyValue: String {
        guard let release = cache.release else { return String(appLocalized: "No policy") }
        return String(
            appLocalized:
                "Minimum \(release.minimumVersion.description) (\(release.minimumBuild)), recommended \(release.recommendedVersion.description) (\(release.recommendedBuild))"
        )
    }

    func checkedValue(now: Date) -> String {
        guard let fetchedAt = cache.fetchedAt else { return String(appLocalized: "Never") }
        return RelativeTime.moment(fetchedAt, now: now)
    }

    var remoteStateValue: String { remoteState.title }
}

extension UpdateState {
    var title: String {
        switch self {
        case .current: String(appLocalized: "Up to date")
        case .recommended: String(appLocalized: "Update recommended")
        case .required: String(appLocalized: "Update required")
        }
    }
}
