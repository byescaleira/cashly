//
//  AdapterUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

public protocol AdapterUseCase: Sendable {
    func budgetAdapted(
        id: UUID,
        amount: Double,
        category: UUID,
        date: TimeInterval,
        summary: String
    ) async throws -> Budget?
    
    func categoryAdapted(
        id: UUID,
        name: String,
        color: String,
        icon: String
    ) async throws -> Category
    
    func userAdapted(
        id: UUID,
        name: String,
        photo: Data?
    ) async throws -> User
    
    func transactionAdapted(
        id: UUID,
        user: UUID,
        participants: [UUID],
        category: UUID,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int
    ) async throws -> Transaction?
}
