import CashlyDomain

extension TransactionKind {
    public var title: String {
        self == .income ? String(appLocalized: "Income") : String(appLocalized: "Expense")
    }
    public var icon: String { self == .income ? "arrow.down.left" : "arrow.up.right" }
}
