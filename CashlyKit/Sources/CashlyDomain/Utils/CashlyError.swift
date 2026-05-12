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

    public var errorDescription: String? {
        switch self {
        case let .persistence(error): return error.errorDescription
        case let .domain(error): return error.errorDescription
        case let .unknown(message): return message
        }
    }

    public var failureReason: String? {
        switch self {
        case let .persistence(error): return error.failureReason
        case let .domain(error): return error.failureReason
        case .unknown: return nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case let .persistence(error): return error.recoverySuggestion
        case let .domain(error): return error.recoverySuggestion
        case .unknown: return "Try again. If the issue persists, contact support."
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
    /// The operation is blocked by the user's current subscription
    /// tier (e.g. trying to add a 4th category on Free). Carries the
    /// gate that fired and the tier that would unlock it.
    case featureGated(feature: String, requiredTier: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidInput(field, _): return "Invalid value for \(field)."
        case let .businessRuleViolated(rule): return "Business rule violated: \(rule)."
        case let .featureGated(feature, tier):
            return "\(feature) requires \(tier)."
        }
    }

    public var failureReason: String? {
        switch self {
        case let .invalidInput(_, reason): return reason
        case .businessRuleViolated: return nil
        case .featureGated: return "Available on the paid tier."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidInput: return "Review the highlighted field and try again."
        case .businessRuleViolated: return nil
        case .featureGated: return "Upgrade to unlock."
        }
    }

    public var description: String { errorDescription ?? "Domain error" }
}
