//
//  TransactionStatus+Color.swift
//  CashlyKit
//
//  UI-side color mapping for TransactionStatus. Lives in CashlyUI so
//  the Domain model stays SwiftUI-free.
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
