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
        case .unavailable: "Indisponível"
        case .checking: "Verificando"
        case .available: "Conectada"
        case .noAccount: "Sem conta"
        case .restricted: "Restrita"
        case .temporarilyUnavailable: "Temporariamente indisponível"
        }
    }
}
