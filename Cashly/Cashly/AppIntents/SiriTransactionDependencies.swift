//
//  SiriTransactionDependencies.swift
//  Cashly
//
//  Singleton bridge so AppIntents can access the data layer without
//  SwiftUI environment. CashlyApp sets `.shared` at launch; intents
//  read it in `perform()`.
//

import CashlyDomain
import CashlyData

@MainActor
final class SiriTransactionDependencies {
    static var shared: SiriTransactionDependencies?

    let transactionDictation: TransactionDictationUseCase
    let transactionUseCase: TransactionUseCase
    let categoryUseCase: CategoryUseCase
    let budgetUseCase: BudgetUseCase

    init(
        transactionDictation: TransactionDictationUseCase,
        transactionUseCase: TransactionUseCase,
        categoryUseCase: CategoryUseCase,
        budgetUseCase: BudgetUseCase
    ) {
        self.transactionDictation = transactionDictation
        self.transactionUseCase = transactionUseCase
        self.categoryUseCase = categoryUseCase
        self.budgetUseCase = budgetUseCase
    }
}
