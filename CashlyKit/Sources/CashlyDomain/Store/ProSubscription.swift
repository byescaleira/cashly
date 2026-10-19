import Foundation

public struct ProSubscription: Equatable, Sendable {
    public enum State: Sendable {
        case subscribed, expired, inGracePeriod, inBillingRetry, revoked
    }

    public enum ExpirationReason: Sendable {
        case cancelled, billingError, priceIncrease, unavailable, unknown
    }

    public static let renewalTolerance: TimeInterval = 86_400

    public var state: State
    public var plan: ShopItem
    public var willRenew: Bool
    public var renewalPlan: ShopItem?
    public var expirationDate: Date?
    public var gracePeriodEnd: Date?
    public var expirationReason: ExpirationReason?
    public var isFreeTrial: Bool

    public init(
        state: State, plan: ShopItem, willRenew: Bool = true, renewalPlan: ShopItem? = nil,
        expirationDate: Date? = nil, gracePeriodEnd: Date? = nil,
        expirationReason: ExpirationReason? = nil, isFreeTrial: Bool = false
    ) {
        self.state = state
        self.plan = plan
        self.willRenew = willRenew
        self.renewalPlan = renewalPlan ?? (willRenew ? plan : nil)
        self.expirationDate = expirationDate
        self.gracePeriodEnd = gracePeriodEnd
        self.expirationReason = expirationReason
        self.isFreeTrial = isFreeTrial
    }

    public var accessEnds: Date? {
        switch state {
        case .subscribed:
            expirationDate.map { willRenew ? $0.addingTimeInterval(Self.renewalTolerance) : $0 }
        case .inGracePeriod: gracePeriodEnd ?? expirationDate
        case .expired, .inBillingRetry, .revoked: nil
        }
    }

    public func grantsPro(at now: Date) -> Bool {
        switch state {
        case .subscribed, .inGracePeriod: (accessEnds ?? .distantFuture) > now
        case .expired, .inBillingRetry, .revoked: false
        }
    }

    public var hasPaymentIssue: Bool {
        state == .inGracePeriod || state == .inBillingRetry
    }

    public var scheduledPlan: ShopItem? {
        guard willRenew, let renewalPlan, renewalPlan != plan else { return nil }
        return renewalPlan
    }

    public static func current(_ statuses: [ProSubscription], at now: Date) -> Self? {
        statuses.max { lhs, rhs in
            let left = (lhs.grantsPro(at: now), lhs.expirationDate ?? .distantPast)
            let right = (rhs.grantsPro(at: now), rhs.expirationDate ?? .distantPast)
            return left.0 == right.0 ? left.1 < right.1 : !left.0
        }
    }
}

extension ShopItem {
    public var planLevel: Int? {
        switch self {
        case .proYearly: 1
        case .proMonthly: 2
        default: nil
        }
    }
}

extension Entitlement {
    public init(_ status: ProSubscription, at now: Date) {
        let ends = status.state == .inGracePeriod ? status.accessEnds : status.expirationDate
        self =
            if status.grantsPro(at: now) {
                status.isFreeTrial
                    ? .trial(expires: ends ?? .distantFuture)
                    : .active(expires: ends ?? .distantFuture)
            } else {
                .expired(min(status.expirationDate ?? now, now))
            }
    }
}
