import CashlyData
import FeatureCore
import Foundation
import Testing

@testable import FeatureStore

@MainActor
struct PaywallOfferTests {
    @Test func paywallIsOfferedAtMostOnceAWeek() throws {
        let database = try CashlyDatabase.open(inMemory: true)
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let store = StoreModel(
            session: SessionModel(provider: database, preference: .disabled),
            client: FakeStoreClient(), defaults: defaults)
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(store.isPaywallOfferDue(now: start))
        store.markPaywallOffered(now: start)
        #expect(!store.isPaywallOfferDue(now: start.addingTimeInterval(6 * 86_400)))
        #expect(store.isPaywallOfferDue(now: start.addingTimeInterval(7 * 86_400)))
    }
}
