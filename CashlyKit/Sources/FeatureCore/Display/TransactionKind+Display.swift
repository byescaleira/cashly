import CashlyDomain

extension TransactionKind {
    public var title: String { self == .income ? "Entrada" : "Saída" }
    public var icon: String { self == .income ? "arrow.down.left" : "arrow.up.right" }
}
