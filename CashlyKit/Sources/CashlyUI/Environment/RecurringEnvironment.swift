//
//  RecurringEnvironment.swift
//  CashlyKit
//
//  Env-injected RecurringTransactionUseCase so ManageRecurringScreen
//  reaches the production actor without touching CashlyDataFactory
//  directly.
//

import SwiftUI
import CashlyDomain
import CashlyMock

private struct RecurringTransactionsKey: EnvironmentKey {
    static let defaultValue: RecurringTransactionUseCase = MockRecurringTransactionActor()
}

public extension EnvironmentValues {
    var recurringTransactions: RecurringTransactionUseCase {
        get { self[RecurringTransactionsKey.self] }
        set { self[RecurringTransactionsKey.self] = newValue }
    }
}
