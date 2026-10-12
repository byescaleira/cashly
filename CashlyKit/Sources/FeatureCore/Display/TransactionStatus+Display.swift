import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension TransactionStatus {
    public var summary: String {
        switch self {
        case .pendingToReceive: String(appLocalized: "To receive")
        case .pendingToPay: String(appLocalized: "To pay")
        case .settled: String(appLocalized: "Paid")
        case .canceled: String(appLocalized: "Canceled")
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

    public var color: Color {
        switch self {
        case .pendingToReceive: .info
        case .pendingToPay: .warning
        case .settled: .positive
        case .canceled: .negative
        }
    }
}
