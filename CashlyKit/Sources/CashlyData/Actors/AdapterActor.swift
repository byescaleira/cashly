//
//  AdapterActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import CashlyDomain
import SwiftData

public actor AdapterActor: AdapterUseCase {
    let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func budgetAdapted(
        id: UUID,
        amount: Double,
        category: UUID,
        date: TimeInterval,
        summary: String
    ) async throws -> Budget? {
        let predicate: Predicate<CategoryEntity> = #Predicate {
            $0.id == category
        }
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        guard let categoryEntity = try modelContext.fetch(descriptor).first else { return nil }
        let category = try await categoryAdapted(
            id: categoryEntity.id,
            name: categoryEntity.name,
            color: categoryEntity.color,
            icon: categoryEntity.icon
        )
        
        return Budget(
            id: id,
            amount: amount,
            category: category,
            date: date.date,
            summary: summary
        )
    }
    
    public func categoryAdapted(
        id: UUID,
        name: String,
        color: String,
        icon: String
    ) async throws -> Category {
        Category(
            id: id,
            name: name.capitalized,
            color: color,
            icon: icon
        )
    }
    
    public func userAdapted(
        id: UUID,
        name: String,
        photo: Data?
    ) async throws -> User {
        User(
            id: id,
            name: name,
            photo: photo
        )
    }
    
    public func transactionAdapted(
        id: UUID,
        user: UUID,
        participants: [UUID],
        category: UUID,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int
    ) async throws -> Transaction? {
        let userPredicate: Predicate<UserEntity> = #Predicate {
            $0.id == user
        }
        let userDescriptor = FetchDescriptor<UserEntity>(
            predicate: userPredicate,
            sortBy: [.init(\.name, order: .forward)]
        )
        let participantsPredicate: Predicate<UserEntity> = #Predicate {
            participants.contains($0.id)
        }
        let participantsDescriptor = FetchDescriptor<UserEntity>(
            predicate: participantsPredicate,
            sortBy: [.init(\.name, order: .forward)]
        )
        let categoryPredicate: Predicate<CategoryEntity> = #Predicate {
            $0.id == category
        }
        let categoryDescriptor = FetchDescriptor(
            predicate: categoryPredicate,
            sortBy: [.init(\.name, order: .forward)]
        )
        
        let participantEntities = try modelContext.fetch(participantsDescriptor)
        guard let userEntity = try modelContext.fetch(userDescriptor).first,
              let categoryEntity = try modelContext.fetch(categoryDescriptor).first,
              let status = TransactionStatus(rawValue: status)
        else { return nil }
        
        let user = try await userAdapted(
            id: userEntity.id,
            name: userEntity.name,
            photo: userEntity.photo
        )
        
        var participants = [User]()
        for participantEntity in participantEntities {
            participants.append(
                try await userAdapted(
                    id: participantEntity.id,
                    name: participantEntity.name,
                    photo: participantEntity.photo
                )
            )
        }
        
        let category = try await categoryAdapted(
            id: categoryEntity.id,
            name: categoryEntity.name,
            color: categoryEntity.color,
            icon: categoryEntity.icon
        )
        
        return CashlyDomain.Transaction(
            id: id,
            user: user,
            participants: participants,
            category: category,
            amount: amount,
            date: date.date,
            summary: summary,
            status: status
        )
    }
}
