import CashlyDomain

extension TransactionStatus {
    public var summary: String {
        switch self {
        case .pendingToReceive: "Pending to Receive"
        case .pendingToPay: "Pending to Pay"
        case .settled: "Settled"
        case .canceled: "Canceled"
        }
    }

    public var icon: String {
        switch self {
        case .pendingToReceive: "arrow.down"
        case .pendingToPay: "arrow.up"
        case .settled: "checkmark"
        case .canceled: "xmark"
        }
    }
}
