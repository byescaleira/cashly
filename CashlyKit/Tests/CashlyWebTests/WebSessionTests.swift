import CashlyWeb
import Foundation
import Testing

struct WebSessionTests {
    private let start = Date(timeIntervalSince1970: 1_792_000_000)

    private func session() throws -> WebSession {
        let vector = try WebVector.load()
        let link = try WebLink(
            try #require(URL(string: vector.link)), host: "cashly.byescaleira.com")
        return try WebSession.pair(with: link, at: start)
    }

    @Test func pairsWithTheLinkSessionAndAFreshOwnerToken() throws {
        let first = try session()
        let second = try session()
        #expect(first.id == "ABEiM0RVZneImaq7zN3u_w")
        #expect(first.ownerToken.count == 43)
        #expect(WebBase64URL.decode(first.ownerToken)?.count == 32)
        #expect(first.ownerToken != second.ownerToken)
        #expect(first.appPublicKey != second.appPublicKey)
        #expect(first.appPublicKey.count == 65)
    }

    @Test func expiresTwentyFourHoursAfterPairing() throws {
        let session = try session()
        #expect(session.expiresAt == start.addingTimeInterval(24 * 60 * 60))
        #expect(!session.isExpired(at: start.addingTimeInterval(23 * 60 * 60)))
        #expect(session.isExpired(at: start.addingTimeInterval(24 * 60 * 60)))
        #expect(session.remaining(at: start.addingTimeInterval(25 * 60 * 60)) == 0)
        #expect(session.remaining(at: start.addingTimeInterval(60 * 60)) == 23 * 60 * 60)
    }

    @Test func storesSessionsInMemory() throws {
        let store = MemoryWebSessionStore()
        let session = try session()
        try store.save([session])
        #expect(store.load() == [session])
        try store.save([])
        #expect(store.load().isEmpty)
    }
}
