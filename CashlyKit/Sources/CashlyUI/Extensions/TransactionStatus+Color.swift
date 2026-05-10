//
//  TransactionStatus+Color.swift
//  CashlyKit
//
//  UI-side color mapping for TransactionStatus. Keeps CashlyDomain free
//  of SwiftUI dependency (G004/G001).
//

import SwiftUI
import CashlyDomain

public extension TransactionStatus {
    var color: Color {
        switch self {
        case .pendingToReceive: return .blue
        case .pendingToPay: return .orange
        case .settled: return .green
        case .canceled: return .red
        }
    }
}
