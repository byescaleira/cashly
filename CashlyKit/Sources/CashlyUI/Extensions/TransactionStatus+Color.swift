import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension TransactionStatus {
    public var color: Color {
        switch self {
        case .pendingToReceive: return .blue
        case .pendingToPay: return .orange
        case .settled: return .green
        case .canceled: return .red
        }
    }
}
