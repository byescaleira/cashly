public enum TransactionSplitMode: Int, CaseIterable, Identifiable, Sendable {
    case equal = 0
    case fixedAmount = 1
    case percentage = 2
    case payerBased = 3

    public var id: Int { rawValue }

    public func value(splitValue: Double?, amount: Double) -> Double? {
        guard let splitValue else { return nil }
        switch self {
        case .equal: return splitValue > .zero ? amount / splitValue : nil
        case .fixedAmount: return splitValue
        case .percentage: return amount * splitValue
        case .payerBased: return .zero
        }
    }
}
