//
//  ParticipantActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

public actor ParticipantActor: ParticipantUseCase {
    let modelContext: ModelContext
    let adapter: AdapterUseCase
    
    public init(
        modelContext: ModelContext,
        adapter: AdapterUseCase
    ) {
        self.modelContext = modelContext
        self.adapter = adapter
    }
    
    public func getParticipant(id: String) async throws -> Participant? {
        let predicate: Predicate<ParticipantEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<ParticipantEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return try await adapter.participantAdapted(
            id: entity.id,
            user: entity.user,
            splitMode: entity.splitMode,
            splitValue: entity.splitValue,
            status: entity.status,
            transaction: entity.transaction
        )
    }
    
    public func getParticipants() async throws -> [Participant] {
        let descriptor = FetchDescriptor<ParticipantEntity>()
        let entities = try modelContext.fetch(descriptor)
        var participants = [Participant]()
        for entity in entities {
            if let participant = try await adapter.participantAdapted(
                id: entity.id,
                user: entity.user,
                splitMode: entity.splitMode,
                splitValue: entity.splitValue,
                status: entity.status,
                transaction: entity.transaction
            ) {
                participants.append(participant)
            }
        }
        return participants
    }
    
    public func getParticipants(transaction: String) async throws -> [Participant] {
        let predicate: Predicate<ParticipantEntity> = #Predicate {
            $0.transaction == transaction
        }
        
        let descriptor = FetchDescriptor<ParticipantEntity>(
            predicate: predicate,
            sortBy: [.init(\.name, order: .forward)]
        )
        
        let entities = try modelContext.fetch(descriptor)
        var participants = [Participant]()
        for entity in entities {
            if let participant = try await adapter.participantAdapted(
                id: entity.id,
                user: entity.user,
                splitMode: entity.splitMode,
                splitValue: entity.splitValue,
                status: entity.status,
                transaction: entity.transaction
            ) {
                participants.append(participant)
            }
        }
        return participants
    }
    
    public func removeParticipant(id: String) async throws {
        let predicate: Predicate<ParticipantEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<ParticipantEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }
    
    public func removeParticipants() async throws {
        let descriptor = FetchDescriptor<ParticipantEntity>()
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }
    
    public func addParticipant(
        id: String,
        user: User,
        splitMode: TransactionSplitMode,
        splitValue: Double,
        status: TransactionStatus,
        transaction: String
    ) async throws {
        let entity = ParticipantEntity(
            id: id,
            user: user.id,
            name: user.name,
            photo: user.photo,
            splitMode: splitMode.rawValue,
            splitValue: splitValue,
            status: status.rawValue,
            transaction: transaction
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
}
