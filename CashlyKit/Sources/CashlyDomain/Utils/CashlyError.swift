//
//  CashlyError.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import PrismFoundation

// MARK: - Umbrella

/// Top-level error returned by Domain APIs and stored in state.
/// Wraps more specific error categories (persistence, domain rules)
/// so call sites can pattern-match by category without losing detail.
public enum CashlyError: PrismError {
    case persistence(PersistenceError)
    case domain(DomainError)
    case unknown(message: String)

    // Legacy generic cases kept for backward compatibility with existing
    // call sites that haven't migrated yet. Prefer the typed variants above.
    case onFetch
    case onSave
    case onRemove

    public var errorDescription: String? {
        switch self {
        case let .persistence(error): return error.errorDescription
        case let .domain(error): return error.errorDescription
        case let .unknown(message): return message
        case .onFetch: return "Failed to fetch data."
        case .onSave: return "Failed to save data."
        case .onRemove: return "Failed to remove data."
        }
    }

    public var failureReason: String? {
        switch self {
        case let .persistence(error): return error.failureReason
        case let .domain(error): return error.failureReason
        case .unknown, .onFetch, .onSave, .onRemove: return nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case let .persistence(error): return error.recoverySuggestion
        case let .domain(error): return error.recoverySuggestion
        case .unknown: return "Try again. If the issue persists, contact support."
        case .onFetch, .onSave, .onRemove: return "Try again."
        }
    }

    public var description: String {
        errorDescription ?? "Unknown error"
    }
}

// MARK: - Persistence

public enum PersistenceError: PrismError {
    case fetchFailed(entity: String, underlying: String)
    case saveFailed(entity: String, underlying: String)
    case removeFailed(entity: String, underlying: String)
    case notFound(entity: String, id: String)

    public var errorDescription: String? {
        switch self {
        case let .fetchFailed(entity, _): return "Failed to fetch \(entity)."
        case let .saveFailed(entity, _): return "Failed to save \(entity)."
        case let .removeFailed(entity, _): return "Failed to remove \(entity)."
        case let .notFound(entity, id): return "\(entity) with id \(id) not found."
        }
    }

    public var failureReason: String? {
        switch self {
        case let .fetchFailed(_, underlying),
             let .saveFailed(_, underlying),
             let .removeFailed(_, underlying):
            return underlying
        case .notFound:
            return "The requested record does not exist in the store."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .fetchFailed, .saveFailed, .removeFailed:
            return "Check your connection and try again."
        case .notFound:
            return "Refresh the list to see the latest data."
        }
    }

    public var description: String { errorDescription ?? "Persistence error" }
}

// MARK: - Domain

public enum DomainError: PrismError {
    case invalidInput(field: String, reason: String)
    case businessRuleViolated(rule: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidInput(field, _): return "Invalid value for \(field)."
        case let .businessRuleViolated(rule): return "Business rule violated: \(rule)."
        }
    }

    public var failureReason: String? {
        switch self {
        case let .invalidInput(_, reason): return reason
        case .businessRuleViolated: return nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidInput: return "Review the highlighted field and try again."
        case .businessRuleViolated: return nil
        }
    }

    public var description: String { errorDescription ?? "Domain error" }
}
