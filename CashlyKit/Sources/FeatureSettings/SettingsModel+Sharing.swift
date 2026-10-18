import CashlyDomain
import Foundation

extension SettingsModel {
    func sharedProfiles(in users: [User]) -> [User] { users.filter(\.isShared) }

    func sharingValue(_ users: [User]) -> String? {
        let count = sharedProfiles(in: users).count
        return count == 0 ? nil : String(appLocalized: "\(count) profiles")
    }
}
