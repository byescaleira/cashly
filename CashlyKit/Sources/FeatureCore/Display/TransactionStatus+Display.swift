import CashlyDomain
import SwiftUI

extension TransactionStatus {
    public var summary: String {
        switch self {
        case .pendingToReceive: "A receber"
        case .pendingToPay: "A pagar"
        case .settled: "Pago"
        case .canceled: "Cancelado"
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
        case .pendingToReceive: .blue
        case .pendingToPay: .orange
        case .settled: .green
        case .canceled: .red
        }
    }
}
