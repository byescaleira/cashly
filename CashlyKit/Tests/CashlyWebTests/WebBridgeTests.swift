import CashlyWeb
import Foundation
import Testing

struct WebBridgeTests {
    private let package = WebPackage(
        appKey: Data(repeating: 4, count: 65), nonce: Data(repeating: 1, count: 12),
        ciphertext: Data(repeating: 2, count: 32))

    @Test func putsThePackageWithTheOwnerToken() async throws {
        let (session, base) = FakeBridgeProtocol.session(statuses: [201])
        try await WebBridge(base: base, session: session)
            .put(package, id: "ABEiM0RVZneImaq7zN3u_w", ownerToken: "owner")
        let request = try #require(FakeBridgeProtocol.requests(to: base).first)
        #expect(request.method == "PUT")
        #expect(request.url.path() == "/bridge/v1/snapshots/ABEiM0RVZneImaq7zN3u_w")
        #expect(request.authorization == "Bearer owner")
        #expect(request.contentType == "application/json")
        #expect(try JSONDecoder().decode(WebPackage.self, from: request.body) == package)
    }

    @Test func deletesWithTheOwnerToken() async throws {
        let (session, base) = FakeBridgeProtocol.session(statuses: [204])
        try await WebBridge(base: base, session: session).delete(id: "abc", ownerToken: "owner")
        let request = try #require(FakeBridgeProtocol.requests(to: base).first)
        #expect(request.method == "DELETE")
        #expect(request.url.path() == "/bridge/v1/snapshots/abc")
        #expect(request.authorization == "Bearer owner")
    }

    @Test func treatsAMissingSnapshotAsDeleted() async throws {
        let (session, base) = FakeBridgeProtocol.session(statuses: [404])
        try await WebBridge(base: base, session: session).delete(id: "abc", ownerToken: "owner")
    }

    @Test(arguments: [
        (403, WebBridgeError.unauthorized), (404, .notFound), (413, .tooLarge),
        (429, .rateLimited), (500, .unavailable(500)),
    ])
    func mapsFailedPuts(status: Int, expected: WebBridgeError) async throws {
        let (session, base) = FakeBridgeProtocol.session(statuses: [status])
        await #expect(throws: expected) {
            try await WebBridge(base: base, session: session)
                .put(package, id: "abc", ownerToken: "owner")
        }
    }

    @Test func updatesAreAcceptedWithOK() async throws {
        let (session, base) = FakeBridgeProtocol.session(statuses: [201, 200])
        let bridge = WebBridge(base: base, session: session)
        try await bridge.put(package, id: "abc", ownerToken: "owner")
        try await bridge.put(package, id: "abc", ownerToken: "owner")
        #expect(FakeBridgeProtocol.requests(to: base).count == 2)
    }
}
