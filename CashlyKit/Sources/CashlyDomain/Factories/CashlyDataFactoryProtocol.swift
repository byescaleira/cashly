//
//  CashlyDataFactoryProtocol.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

@MainActor
public protocol CashlyDataFactoryProtocol {
    func makeAdapter() -> AdapterUseCase
    func makeBudgetUseCase() -> BudgetUseCase
    func makeCategoryUseCase() -> CategoryUseCase
    func makeUserUseCase() -> UserUseCase
    func makeUserPreferences() -> UserPreferencesUseCase
    func makeSubscriptionUseCase() -> SubscriptionUseCase
    func makeFeatureGate() -> FeatureGateUseCase
    func makeTransactionUseCase() -> TransactionUseCase
    func makeTagUseCase() -> TagUseCase
    func makeParticipantUseCase() -> ParticipantUseCase
}
