public enum TransactionKind: Int, CaseIterable, Identifiable, Sendable {
    case expense = 0
    case income = 1

    public var id: Int { rawValue }
}
