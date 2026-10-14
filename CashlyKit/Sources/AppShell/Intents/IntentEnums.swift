import AppIntents
import CashlyDomain
import FeatureCore

public enum PaymentStatusOption: String, AppEnum {
    case paid
    case pending

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Status")
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .paid: DisplayRepresentation(title: "Paid", image: .init(systemName: "checkmark")),
        .pending: DisplayRepresentation(title: "Pending", image: .init(systemName: "clock")),
    ]

    var request: TransactionRequest.Status {
        switch self {
        case .paid: .paid
        case .pending: .pending
        }
    }
}

public enum SplitModeOption: String, AppEnum {
    case equal
    case percentage
    case fixedAmount

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Split Mode")
    public static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .equal: "Equal",
        .percentage: "Percentage",
        .fixedAmount: "Fixed amount",
    ]

    var mode: TransactionSplitMode {
        switch self {
        case .equal: .equal
        case .percentage: .percentage
        case .fixedAmount: .fixedAmount
        }
    }
}
