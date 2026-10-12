import CashlyDomain

extension TransactionSplitMode {
    public var summary: String {
        switch self {
        case .equal: String(appLocalized: "Equal")
        case .fixedAmount: String(appLocalized: "Fixed amount")
        case .percentage: String(appLocalized: "Percentage")
        case .payerBased: String(appLocalized: "Who paid")
        }
    }

    public var description: String {
        switch self {
        case .equal: String(appLocalized: "Splits the total equally among all participants.")
        case .fixedAmount: String(appLocalized: "Sets a fixed amount for each participant.")
        case .percentage: String(appLocalized: "Splits the total by percentage.")
        case .payerBased:
            String(appLocalized: "One person pays the full amount and the others owe them.")
        }
    }
}
