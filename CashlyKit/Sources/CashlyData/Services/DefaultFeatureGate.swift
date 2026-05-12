//
//  DefaultFeatureGate.swift
//  CashlyKit
//
//  Production FeatureGateUseCase: combines the SubscriptionUseCase
//  tier with live counts from User/Category/Budget use cases. Pro
//  short-circuits to .allowed for every gate.
//

import Foundation
import CashlyDomain

public actor DefaultFeatureGate: FeatureGateUseCase {
    private let subscription: SubscriptionUseCase
    private let userUseCase: UserUseCase
    private let categoryUseCase: CategoryUseCase
    private let budgetUseCase: BudgetUseCase

    public nonisolated let limits: FeatureGateLimits

    public init(
        subscription: SubscriptionUseCase,
        userUseCase: UserUseCase,
        categoryUseCase: CategoryUseCase,
        budgetUseCase: BudgetUseCase,
        limits: FeatureGateLimits = .freeDefault
    ) {
        self.subscription = subscription
        self.userUseCase = userUseCase
        self.categoryUseCase = categoryUseCase
        self.budgetUseCase = budgetUseCase
        self.limits = limits
    }

    public func decide(_ feature: FeatureGate) async -> FeatureGateDecision {
        let status = await subscription.currentStatus()
        if status.tier == .pro { return .allowed }

        switch feature {
        case .addUser:
            let count = (try? await userUseCase.getUsers().count) ?? 0
            return count < limits.maxUsers
                ? .allowed
                : .blocked(feature: .addUser, requiredTier: .pro)

        case .addCategory:
            let count = (try? await categoryUseCase.getCategories().count) ?? 0
            return count < limits.maxCategories
                ? .allowed
                : .blocked(feature: .addCategory, requiredTier: .pro)

        case .addBudget:
            let count = (try? await budgetUseCase.getBudgets().count) ?? 0
            return count < limits.maxBudgets
                ? .allowed
                : .blocked(feature: .addBudget, requiredTier: .pro)

        case .intelligence, .multiUser:
            // Both are Pro-only features regardless of count.
            return .blocked(feature: feature, requiredTier: .pro)
        }
    }
}
