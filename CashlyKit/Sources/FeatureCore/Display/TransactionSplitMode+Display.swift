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
            String(
                appLocalized:
                    "Kept from an older record: you paid it all and no share is recorded for the others."
            )
        }
    }

    public static func selectable(keeping current: TransactionSplitMode?) -> [TransactionSplitMode]
    {
        allCases.filter { $0 != .payerBased || $0 == current }
    }
}
