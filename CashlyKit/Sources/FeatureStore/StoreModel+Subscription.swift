import CashlyDomain
import FeatureCore
import Foundation

public struct ProNotice: Equatable, Sendable {
    public let title: String
    public let detail: String
}

public struct PlanSwitch: Equatable, Sendable {
    public let target: ShopItem
    public let title: String
    public let detail: String
    public let message: String
}

extension StoreModel {
    public var planTitle: String {
        isOnHold ? String(appLocalized: "On Hold") : entitlement.title
    }

    public var planDetail: String? {
        guard let subscription else { return entitlement.detail }
        switch subscription.state {
        case .inGracePeriod:
            guard let ends = subscription.gracePeriodEnd else { return entitlement.detail }
            return String(
                appLocalized: "Pro until \(Entitlement.day(ends)) while Apple retries the payment")
        case .inBillingRetry:
            return String(appLocalized: "Pro returns once the payment goes through")
        case .expired, .revoked: return entitlement.detail
        case .subscribed:
            guard let date = subscription.expirationDate.map(Entitlement.day) else {
                return entitlement.detail
            }
            if subscription.scheduledPlan == .proMonthly {
                return String(appLocalized: "Switches to Monthly on \(date)")
            }
            if subscription.scheduledPlan == .proYearly {
                return String(appLocalized: "Switches to Annual on \(date)")
            }
            if !subscription.willRenew {
                return String(appLocalized: "Pro until \(date) (renewal off)")
            }
            return entitlement.detail
        }
    }

    public var paymentNotice: ProNotice? {
        guard let subscription, subscription.hasPaymentIssue else { return nil }
        return ProNotice(
            title: String(appLocalized: "Update Payment Method"),
            detail: subscription.state == .inGracePeriod
                ? String(
                    appLocalized:
                        "Apple couldn't charge your subscription. Update your payment method to keep Cashly Pro."
                )
                : String(
                    appLocalized:
                        "Apple couldn't charge your subscription. Update your payment method to bring Cashly Pro back."
                ))
    }

    public var isOnHold: Bool {
        subscription?.state == .inBillingRetry
    }

    public var canSubscribe: Bool {
        !entitlement.isActive && !isOnHold
    }

    public var renewalNotice: ProNotice? {
        guard let subscription, subscription.state == .subscribed, !subscription.willRenew,
            let ends = subscription.expirationDate
        else { return nil }
        return ProNotice(
            title: String(appLocalized: "Turn On Renewal"),
            detail: String(appLocalized: "Keep Cashly Pro after \(Entitlement.day(ends))."))
    }

    public var planSwitch: PlanSwitch? {
        guard let subscription, subscription.state == .subscribed, subscription.willRenew,
            !subscription.isFreeTrial,
            let level = subscription.plan.planLevel,
            let target = ShopCatalog.plans.first(where: {
                $0 != subscription.plan && $0 != subscription.scheduledPlan
            }),
            let targetLevel = target.planLevel, let product = products[target],
            let renews = subscription.expirationDate
        else { return nil }
        return targetLevel < level
            ? upgrade(to: target, price: product.displayPrice)
            : downgrade(to: target, price: product.displayPrice, on: renews)
    }

    public func switchPlan() async -> Bool {
        guard let target = planSwitch?.target else { return false }
        return await buy(target)
    }

    private func upgrade(to target: ShopItem, price: String) -> PlanSwitch {
        PlanSwitch(
            target: target, title: String(appLocalized: "Switch to Annual"),
            detail: String(appLocalized: "Starts today. Apple credits the unused time."),
            message: String(
                appLocalized:
                    "Annual starts today for \(price)/year. Apple refunds the unused part of your monthly plan in proportion."
            ))
    }

    private func downgrade(to target: ShopItem, price: String, on date: Date) -> PlanSwitch {
        let day = Entitlement.day(date)
        return PlanSwitch(
            target: target, title: String(appLocalized: "Switch to Monthly"),
            detail: String(appLocalized: "Starts at the next renewal."),
            message: String(
                appLocalized:
                    "You keep Annual until \(day). Monthly starts at the next renewal for \(price)/month."
            ))
    }
}
