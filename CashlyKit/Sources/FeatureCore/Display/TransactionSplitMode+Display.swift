import CashlyDomain

extension TransactionSplitMode {
    public var summary: String {
        switch self {
        case .equal: "Equal"
        case .fixedAmount: "Fixed Amount"
        case .percentage: "Percentage"
        case .payerBased: "Payer Based"
        }
    }

    public var description: String {
        switch self {
        case .equal: "Split the total equally among all participants."
        case .fixedAmount: "Assign a fixed amount to each participant."
        case .percentage: "Distribute the total based on percentages."
        case .payerBased: "One participant pays the full amount, others are marked as owing."
        }
    }
}
