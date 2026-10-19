import CashlyDomain
import FeatureStore
import StoreKitTest
import Testing

extension StoreKitTests {
    @MainActor @Suite struct ShopPurchase {
        @Test func nonConsumableUnlocksAndStaysOwned() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.store.buy(.iconsFashion))
            #expect(fixture.store.owns(.iconsFashion))
            #expect(!fixture.store.owns(.iconsSports))
            let other = try await StoreKitFixture.model(on: fixture.database)
            await other.refresh()
            #expect(other.owns(.iconsFashion))
        }

        @Test func bundleUnlocksEveryPackInIt() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.store.buy(.iconsAll))
            #expect(ShopCatalog.items(in: .icons).allSatisfy(fixture.store.owns))
            #expect(!fixture.store.owns(.avatarsFarm))
        }

        @Test func restoringBringsTheItemsBack() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.store.buy(.avatarsOcean))
            let other = try await StoreKitFixture.model(on: fixture.database)
            #expect(await other.restoreItem(.avatarsOcean))
            #expect(await other.restoreItems())
        }

        @Test func refundedItemIsTakenBack() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.store.buy(.accentNeon))
            let transaction = try fixture.transaction(for: .accentNeon)
            try fixture.session.refundTransaction(identifier: transaction.identifier)
            try await fixture.settle { !fixture.store.owns(.accentNeon) }
            #expect(!fixture.store.owns(.accentNeon))
        }

        @Test func consumableCreditsTheJourneyEveryTime() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.store.buy(.freezes3))
            #expect(await fixture.store.buy(.freezes3))
            let credits = try await fixture.events().filter { $0.kind == .freezesCredited }
            #expect(credits.count == 2)
            #expect(credits.allSatisfy { $0.count == 3 })
            #expect(!fixture.store.owned.contains(.freezes3))
        }

        @Test func streakRestoreAndRerollsAreCredited() async throws {
            let fixture = try await StoreKitFixture()
            #expect(await fixture.store.buy(.streakRestore))
            #expect(await fixture.store.buy(.challengeRerolls))
            let kinds = try await fixture.events().map(\.kind)
            #expect(kinds.contains(.streakRestored))
            #expect(kinds.contains(.rerollsCredited))
        }
    }
}
