//
//  CashlyDataFactoryProtocol.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData

public protocol CashlyDataFactoryProtocol: Sendable {
    func makeModelContext() -> ModelContext
    func makeAdapter() -> AdapterUseCase
    func makeBudgetUseCase() -> BudgetUseCase
    func makeCategoryUseCase() -> CategoryUseCase
    func makeUserUseCase() -> UserUseCase
    func makeTransactionUseCase() -> TransactionUseCase
    func makeTagUseCase() -> TagUseCase
    func makeParticipantUseCase() -> ParticipantUseCase
}
