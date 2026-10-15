import Foundation

extension StoreModel {
    static let paywallOfferKey = "cashly.paywall.lastOffer"
    static let paywallOfferInterval: TimeInterval = 7 * 86_400

    public func isPaywallOfferDue(now: Date = .now) -> Bool {
        guard let last = defaults.object(forKey: Self.paywallOfferKey) as? Date else { return true }
        return now.timeIntervalSince(last) >= Self.paywallOfferInterval
    }

    public func markPaywallOffered(now: Date = .now) {
        defaults.set(now, forKey: Self.paywallOfferKey)
    }
}
