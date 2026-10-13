import CashlyDomain
import Foundation

public struct PaywallPlan: Identifiable, Hashable {
    public let item: ShopItem
    public let product: StoreProduct
    public let savingPercent: Int?

    public var id: ShopItem { item }
    public var isBestValue: Bool { savingPercent != nil }

    public var monthlyEquivalent: String? {
        guard let period = product.period, period != .month else { return nil }
        return product.formatted(product.price / Decimal(period.months))
    }
}

extension StoreModel {
    public var plans: [PaywallPlan] {
        [ShopItem.proYearly, .proMonthly].compactMap { item in
            products[item].map {
                PaywallPlan(item: item, product: $0, savingPercent: saving(for: $0))
            }
        }
    }

    public var selected: PaywallPlan? {
        plans.first { $0.item == selectedPlan }
    }

    public var trialDays: Int? {
        guard introEligible.contains(selectedPlan) else { return nil }
        return products[selectedPlan]?.trialDays
    }

    private func saving(for product: StoreProduct) -> Int? {
        guard let period = product.period, period != .month,
            let monthly = products[.proMonthly], monthly.price > 0
        else { return nil }
        let reference = monthly.price * Decimal(period.months)
        let saving = (reference - product.price) / reference * 100
        let rounded = Int(NSDecimalNumber(decimal: saving).doubleValue)
        return rounded > 0 ? rounded : nil
    }
}
