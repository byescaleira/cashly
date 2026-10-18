import CashlyData
import CashlyDomain
import CashlyWeb
import CryptoKit
import FeatureCore
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct WebSharingModelTests {
    private let owner = User(id: "owner", name: "Dana Teixeira")
    private let session = "ABEiM0RVZneImaq7zN3u_w"
    private let webKey =
        "BGv4XV_oRZixDKYZnsCczX013NcZX90dx3N6DGcAbvJRuVLyXuwd7tH8oZGDiZBGY1fTFK37fpdguNmvyPOala0"
    private let webPrivateKey = Data(repeating: 0x1f, count: 32)
    private let start = Date(timeIntervalSince1970: 1_792_316_460)

    private var link: URL {
        URL(string: "https://cashly.byescaleira.com/link?s=\(session)&k=\(webKey)")
            ?? URL(filePath: "/")
    }

    private func model(
        statuses: [Int], store: MemoryWebSessionStore = MemoryWebSessionStore(),
        now: Date? = nil
    ) async throws -> (WebSharingModel, URL) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let (urlSession, base) = FakeBridgeProtocol.session(statuses: statuses)
        let page = try #require(URL(string: "https://cashly.byescaleira.com/app"))
        let date = now ?? start
        let model = WebSharingModel(
            provider: database, endpoints: WebEndpoints(bridge: base, page: page), store: store,
            urlSession: urlSession, preference: .disabled, now: { date })
        return (model, base)
    }

    @Test func confirmsAValidLinkOnlyWithPro() async throws {
        let (model, _) = try await model(statuses: [201])
        #expect(model.receive(link) == .needsPro)
        #expect(model.pendingLink == nil)
        model.isPro = true
        #expect(model.receive(link) == .confirming)
        #expect(model.pendingLink?.sessionID == session)
    }

    @Test func rejectsAnInvalidLink() async throws {
        let (model, _) = try await model(statuses: [201])
        model.isPro = true
        let url = try #require(URL(string: "https://cashly.byescaleira.com/link?s=abc&k=def"))
        #expect(model.receive(url) == .invalid)
        #expect(model.linkError != nil)
        #expect(model.pendingLink == nil)
        let other = try #require(URL(string: "cashly://transactions/new"))
        #expect(model.receive(other) == .ignored)
    }

    @Test func connectingSendsASnapshotOnlyThatBrowserOpens() async throws {
        let store = MemoryWebSessionStore()
        let (model, base) = try await model(statuses: [201], store: store)
        model.isPro = true
        model.receive(link)
        await model.connect()
        #expect(model.pendingLink == nil)
        #expect(model.sessions.map(\.id) == [session])
        #expect(store.load().map(\.id) == [session])
        let stored = try #require(model.sessions.first)
        #expect(stored.lastSentAt == start)
        let request = try #require(FakeBridgeProtocol.requests(to: base).first)
        #expect(request.method == "PUT")
        #expect(request.url.lastPathComponent == session)
        #expect(request.authorization == "Bearer \(stored.ownerToken)")
        let package = try JSONDecoder().decode(WebPackage.self, from: request.body)
        #expect(package.v == 2)
        let browser = try P256.KeyAgreement.PrivateKey(rawRepresentation: webPrivateKey)
        let appKey = try P256.KeyAgreement.PublicKey(
            x963Representation: try #require(Data(base64Encoded: package.appKey)))
        let key = try browser.sharedSecretFromKeyAgreement(with: appKey)
            .hkdfDerivedSymmetricKey(
                using: SHA256.self, salt: try #require(WebBase64URL.decode(session)),
                sharedInfo: WebCipher.info, outputByteCount: 32)
        let plaintext = try WebCipher.open(
            package, key: key.withUnsafeBytes { Data($0) }, sessionID: session)
        let snapshot = try JSONDecoder().decode(WebSnapshot.self, from: plaintext)
        #expect(snapshot.profile.name == "Dana Teixeira")
        #expect(snapshot.month.start == "2026-10-01")
    }

    @Test func anExpiredQRCodeShowsAFriendlyError() async throws {
        let (model, _) = try await model(statuses: [404])
        model.isPro = true
        model.receive(link)
        await model.connect()
        #expect(model.sessions.isEmpty)
        #expect(model.connectError == WebSharingModel.pairingError(WebBridgeError.notFound))
        #expect(model.pendingLink != nil)
    }

    @Test func disconnectingDeletesOnTheBridgeAndForgetsTheSession() async throws {
        let store = MemoryWebSessionStore()
        let (model, base) = try await model(statuses: [201, 204], store: store)
        model.isPro = true
        model.receive(link)
        await model.connect()
        let connected = try #require(model.sessions.first)
        await model.disconnect(connected)
        #expect(model.sessions.isEmpty)
        #expect(store.load().isEmpty)
        let delete = try #require(FakeBridgeProtocol.requests(to: base).last)
        #expect(delete.method == "DELETE")
        #expect(delete.authorization == "Bearer \(connected.ownerToken)")
    }

    @Test func expiredSessionsAreDroppedOnLaunch() async throws {
        let pairing = try WebLink(link, host: "cashly.byescaleira.com")
        let old = try WebSession.pair(with: pairing, at: start.addingTimeInterval(-25 * 60 * 60))
        let store = MemoryWebSessionStore([old])
        let (model, _) = try await model(statuses: [204], store: store)
        #expect(model.sessions.isEmpty)
        #expect(store.load().isEmpty)
    }

    @Test func liveSessionsSurviveALaunchAndResend() async throws {
        let pairing = try WebLink(link, host: "cashly.byescaleira.com")
        let live = try WebSession.pair(with: pairing, at: start.addingTimeInterval(-60 * 60))
        let store = MemoryWebSessionStore([live])
        let (model, base) = try await model(statuses: [200], store: store)
        #expect(model.sessions.map(\.id) == [session])
        model.isPro = true
        await model.send()
        #expect(model.sessions.first?.lastSentAt == start)
        #expect(FakeBridgeProtocol.requests(to: base).contains { $0.method == "PUT" })
        #expect(model.overviewValue == String(appLocalized: "\(1) connected"))
    }

    @Test func showsTheStateOfEachSessionWithItsColor() async throws {
        let pairing = try WebLink(link, host: "cashly.byescaleira.com")
        var sent = try WebSession.pair(with: pairing, at: start)
        sent.lastSentAt = start
        var unsent = sent
        unsent.lastSentAt = nil
        let (model, _) = try await model(statuses: [500], store: MemoryWebSessionStore([sent]))
        #expect(model.status(of: sent, at: start) == String(appLocalized: "Paused"))
        #expect(model.statusColor(of: sent) == .retroMustard)
        model.isPro = true
        #expect(model.statusColor(of: sent) == .positive)
        #expect(model.status(of: sent, at: start) != String(appLocalized: "Paused"))
        #expect(model.status(of: unsent, at: start) == String(appLocalized: "Not sent yet"))
        #expect(model.statusColor(of: unsent) == .secondary)
        await model.send()
        #expect(model.status(of: sent, at: start) == String(appLocalized: "Retrying"))
        #expect(model.statusColor(of: sent) == .negative)
    }

    @Test func doesNotSendWithoutPro() async throws {
        let pairing = try WebLink(link, host: "cashly.byescaleira.com")
        let live = try WebSession.pair(with: pairing, at: start)
        let (model, base) = try await model(
            statuses: [200], store: MemoryWebSessionStore([live]))
        await model.send()
        #expect(FakeBridgeProtocol.requests(to: base).isEmpty)
        #expect(model.sessions.first?.lastSentAt == nil)
    }
}
