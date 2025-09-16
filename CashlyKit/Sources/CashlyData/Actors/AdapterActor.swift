//
//  AdapterActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import CashlyDomain
import SwiftData

@ModelActor
public actor AdapterActor: AdapterUseCase {
    public func budgetAdapted(
        id: String,
        amount: Double,
        category: String,
        date: Int,
        summary: String
    ) async throws -> Budget? {
        let categoryPredicate: Predicate<CategoryEntity> = #Predicate {
            $0.id == category
        }
        let categoryDescriptor = FetchDescriptor<CategoryEntity>(predicate: categoryPredicate)
        
        guard let categoryEntity = try modelContext.fetch(categoryDescriptor).first,
              let category = try await categoryAdapted(
                id: categoryEntity.id,
                user: categoryEntity.user,
                name: categoryEntity.name,
                color: categoryEntity.color,
                icon: categoryEntity.icon
              )
        else { return nil }
        
        return Budget(
            id: id,
            amount: amount,
            category: category,
            date: date,
            summary: summary
        )
    }
    
    public func categoryAdapted(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws -> Category? {
        let userPredicate: Predicate<UserEntity> = #Predicate {
            $0.id == user
        }
        let userDescriptor = FetchDescriptor<UserEntity>(predicate: userPredicate)
        
        guard let userEntity = try modelContext.fetch(userDescriptor).first else { return nil }
        let user = try await userAdapted(
            id: userEntity.id,
            name: userEntity.name,
            photo: userEntity.photo
        )
        
        return Category(
            id: id,
            user: user,
            name: name.capitalized,
            color: color,
            icon: icon
        )
    }
    
    public func userAdapted(
        id: String,
        name: String,
        photo: String
    ) async throws -> User {
        User(
            id: id,
            name: name,
            photo: photo
        )
    }
    
    public func tagAdapted(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws -> Tag? {
        let userPredicate: Predicate<UserEntity> = #Predicate {
            $0.id == user
        }
        let userDescriptor = FetchDescriptor<UserEntity>(predicate: userPredicate)
        
        guard let userEntity = try modelContext.fetch(userDescriptor).first else { return nil }
        let user = try await userAdapted(
            id: userEntity.id,
            name: userEntity.name,
            photo: userEntity.photo
        )
        
        return Tag(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon
        )
    }
    
    public func transactionAdapted(
        id: String,
        participants: [String],
        budget: String,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int,
        splitMode: Int?,
        splitValue: Double?,
        paymentsPlan: Int?
    ) async throws -> Transaction? {
        let participantsPredicate: Predicate<ParticipantEntity> = #Predicate {
            participants.contains($0.id)
        }
        
        let participantsDescriptor = FetchDescriptor<ParticipantEntity>(
            predicate: participantsPredicate,
            sortBy: [.init(\.name, order: .forward)]
        )
        
        let budgetPredicate: Predicate<BudgetEntity> = #Predicate {
            $0.id == budget
        }
        
        let budgetDescriptor = FetchDescriptor<BudgetEntity>(predicate: budgetPredicate)
        
        let participantEntities = try modelContext.fetch(participantsDescriptor)
        guard let budgetEntity = try modelContext.fetch(budgetDescriptor).first,
              let budget = try await budgetAdapted(
                  id: budgetEntity.id,
                  amount: budgetEntity.amount,
                  category: budgetEntity.category,
                  date: budgetEntity.date,
                  summary: budgetEntity.summary
              ),
              let status = TransactionStatus(rawValue: status)
        else { return nil }
        
        var participants = [Participant]()
        for participantEntity in participantEntities {
            if let participant = try await participantAdapted(
                id: participantEntity.id,
                user: participantEntity.user,
                splitMode: participantEntity.splitMode,
                splitValue: participantEntity.splitValue,
                status: participantEntity.status,
                transaction: participantEntity.transaction
            ) {
                participants.append(participant)
            }
        }
        
        return CashlyDomain.Transaction(
            id: id,
            participants: participants,
            budget: budget,
            amount: amount,
            date: date,
            summary: summary,
            status: status,
            splitMode: TransactionSplitMode(rawValue: splitMode ?? -1),
            splitValue: splitValue,
            paymentsPlan: paymentsPlan
        )
    }
    
    public func participantAdapted(
        id: String,
        user: String,
        splitMode: Int,
        splitValue: Double,
        status: Int,
        transaction: String
    ) async throws -> Participant? {
        let userPredicate: Predicate<UserEntity> = #Predicate {
            $0.id == user
        }
        let userDescriptor = FetchDescriptor<UserEntity>(predicate: userPredicate)
        
        guard let userEntity = try modelContext.fetch(userDescriptor).first,
              let splitMode = TransactionSplitMode(rawValue: splitMode),
              let status = TransactionStatus(rawValue: status)
        else { return nil }
        let user = try await userAdapted(
            id: userEntity.id,
            name: userEntity.name,
            photo: userEntity.photo
        )
        
        return Participant(
            id: id,
            user: user,
            splitMode: splitMode,
            splitValue: splitValue,
            status: status,
            transaction: transaction
        )
    }
}
