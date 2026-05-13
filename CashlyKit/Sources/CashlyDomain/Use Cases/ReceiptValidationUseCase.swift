//
//  ReceiptValidationUseCase.swift
//  CashlyKit
//
//  Server-side receipt validation contract. Implementations either
//  forward the StoreKit 2 JWS payload to a Cashly backend for
//  cross-check (production) or rubber-stamp it locally (dev /
//  preview). The protocol stays in Domain so neither StoreKit nor
//  URLSession leak into the rest of the codebase.
//

import Foundation

public struct ReceiptPayload: Sendable, Equatable {
    /// StoreKit 2 JWS representation of a `Transaction` or
    /// `RenewalInfo`. Pass through untouched.
    public let jws: String
    /// Bundle identifier the receipt was issued for. Used by the
    /// backend to reject cross-app replay.
    public let bundleId: String
    /// Optional app-account-token forwarded so the backend can map
    /// the purchase to a Cashly account when accounts ship.
    public let appAccountToken: UUID?

    public init(jws: String, bundleId: String, appAccountToken: UUID? = nil) {
        self.jws = jws
        self.bundleId = bundleId
        self.appAccountToken = appAccountToken
    }
}

public enum ReceiptValidationResult: Sendable, Equatable {
    /// Backend confirmed the receipt and reports the entitled tier.
    case valid(tier: SubscriptionTier, expiresAt: Date?)
    /// Receipt rejected. Reason is opaque on the client; UI shows a
    /// generic "try again" message.
    case invalid(reason: String)
    /// Backend unreachable. Caller should treat as "skip" and rely
    /// on StoreKit's local verification until the next attempt.
    case unreachable
}

public protocol ReceiptValidationUseCase: Sendable {
    /// Validates a single receipt payload against the Cashly backend.
    func validate(_ payload: ReceiptPayload) async -> ReceiptValidationResult
}
