import CashlyDomain
import CloudKit

public enum CloudAccount: Equatable {
    case unavailable, checking, available, noAccount, restricted, temporarilyUnavailable

    init(_ status: CKAccountStatus) {
        switch status {
        case .available: self = .available
        case .noAccount: self = .noAccount
        case .restricted: self = .restricted
        case .temporarilyUnavailable: self = .temporarilyUnavailable
        default: self = .unavailable
        }
    }

    var title: String {
        switch self {
        case .unavailable: String(appLocalized: "Unavailable")
        case .checking: String(appLocalized: "Checking")
        case .available: String(appLocalized: "Connected")
        case .noAccount: String(appLocalized: "No account")
        case .restricted: String(appLocalized: "Restricted")
        case .temporarilyUnavailable: String(appLocalized: "Temporarily unavailable")
        }
    }
}
