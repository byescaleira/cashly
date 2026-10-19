import CashlyDomain
import FeatureStore
import Foundation
import Testing

extension StoreKitTests {
    @MainActor @Suite struct Catalog {
        @Test func everyShopItemLoadsFromTheStore() async throws {
            let fixture = try await StoreKitFixture()
            #expect(fixture.store.hasLoaded)
            #expect(Set(fixture.store.products.keys) == Set(ShopItem.allCases))
            #expect(fixture.store.entitlement == .none)
        }

        @Test func plansCarryPriceAndPeriodAndTrial() async throws {
            let fixture = try await StoreKitFixture()
            let monthly = try #require(fixture.store.products[.proMonthly])
            let yearly = try #require(fixture.store.products[.proYearly])
            #expect(monthly.displayPrice.contains("14,90"))
            #expect(monthly.period == .month)
            #expect(monthly.trialDays == 7)
            #expect(yearly.displayPrice.contains("99,90"))
            #expect(yearly.period == .year)
            #expect(yearly.trialDays == 7)
        }

        @Test func shopItemsCarryTheirPrices() async throws {
            let fixture = try await StoreKitFixture()
            #expect(fixture.store.products[.iconsAll]?.displayPrice.contains("44,90") == true)
            #expect(fixture.store.products[.freezes3]?.displayPrice.contains("6,90") == true)
            #expect(fixture.store.products[.iconsFashion]?.period == nil)
        }

        @Test func decimalPricesKeepTheCents() async throws {
            let fixture = try await StoreKitFixture()
            withKnownIssue(
                "StoreKit Testing drops the cents of Product.price with the pt_BR storefront",
                isIntermittent: true
            ) {
                #expect(fixture.store.products[.proMonthly]?.price == Decimal(string: "14.90"))
                #expect(fixture.store.products[.proYearly]?.price == Decimal(string: "99.90"))
            }
        }
    }
}
