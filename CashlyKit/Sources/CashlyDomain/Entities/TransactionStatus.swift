public enum TransactionStatus: Int, CaseIterable, Identifiable, Sendable {
    case pendingToReceive = 3
    case pendingToPay = 2
    case settled = 0
    case canceled = 1

    public var id: Int { rawValue }

    public var reverse: TransactionStatus {
        switch self {
        case .pendingToReceive: .pendingToPay
        case .pendingToPay: .pendingToReceive
        case .settled: .settled
        case .canceled: .canceled
        }
    }
}
