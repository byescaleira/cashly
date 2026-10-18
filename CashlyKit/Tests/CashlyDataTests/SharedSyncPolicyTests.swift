import CashlyDomain
import Foundation
import Testing

@testable import CashlyData

struct SharedSyncPolicyTests {
    typealias Record = SharedSyncState.Record
    let past = Date(timeIntervalSince1970: 1_000)
    let now = Date(timeIntervalSince1970: 2_000)

    @Test func incomingWinsUnlessThisDeviceEditedLater() {
        #expect(SharedSyncPolicy.incoming(nil, remoteEditedAt: now) == .apply)
        #expect(SharedSyncPolicy.incoming(Record(digest: "a"), remoteEditedAt: now) == .apply)
        #expect(
            SharedSyncPolicy.incoming(
                Record(digest: "a", local: "b", editedAt: past), remoteEditedAt: now)
                == .apply)
        #expect(
            SharedSyncPolicy.incoming(
                Record(digest: "a", local: "b", editedAt: now), remoteEditedAt: past)
                == .keepLocal)
    }

    @Test func remoteDeletionLosesOnlyToAnUnsentEdit() {
        let edited = Record(digest: "a", local: "b", editedAt: now)
        #expect(SharedSyncPolicy.remoteDeletion(nil) == .deleteLocal)
        #expect(SharedSyncPolicy.remoteDeletion(Record(digest: "a")) == .deleteLocal)
        #expect(SharedSyncPolicy.remoteDeletion(edited) == .recreate)
        #expect(SharedSyncPolicy.missingOnServer(Record(digest: "a")) == .deleteLocal)
        #expect(SharedSyncPolicy.missingOnServer(edited) == .recreate)
    }

    @Test func anEditThatWentBackToTheConfirmedContentIsNotPending() {
        let reverted = Record(digest: "a", local: "a", editedAt: now)
        #expect(SharedSyncPolicy.pendingEdit(reverted) == nil)
        #expect(SharedSyncPolicy.incoming(reverted, remoteEditedAt: past) == .apply)
        #expect(SharedSyncPolicy.remoteDeletion(reverted) == .deleteLocal)
        #expect(SharedSyncPolicy.missingOnServer(reverted) == .deleteLocal)
    }

    @Test func eachProfileBelongsToOneEngine() {
        let registry = SharedZoneRegistry()
        #expect(registry.claim("home", for: .joined))
        #expect(!registry.claim("home", for: .owned))
        #expect(registry.claim("home", for: .joined))
        registry.release("home", from: .owned)
        #expect(registry.scope(of: "home") == .joined)
        registry.release("home", from: .joined)
        #expect(registry.claim("home", for: .owned))
    }

    @Test func conflictsResendOnlyNewerConfirmedEdits() {
        let edited = Record(digest: "a", local: "b", editedAt: now)
        #expect(
            SharedSyncPolicy.conflict(edited, serverEditedAt: past, serverDigest: "c") == .resend)
        #expect(
            SharedSyncPolicy.conflict(
                edited, serverEditedAt: now.addingTimeInterval(1),
                serverDigest: "c") == .adoptServer)
        #expect(
            SharedSyncPolicy.conflict(edited, serverEditedAt: past, serverDigest: "b")
                == .adoptServer)
    }

    @Test func recordsNeverConfirmedHereAdoptTheServer() {
        let lost = Record(digest: nil, local: "b", editedAt: now)
        #expect(
            SharedSyncPolicy.conflict(lost, serverEditedAt: past, serverDigest: "c")
                == .adoptServer)
        #expect(
            SharedSyncPolicy.conflict(nil, serverEditedAt: past, serverDigest: "c")
                == .adoptServer)
    }

    @Test func outgoingNeverInventsAnEditDate() {
        #expect(SharedSyncPolicy.outgoing(Record(digest: "a"), currentDigest: "a") == nil)
        #expect(
            SharedSyncPolicy.outgoing(Record(digest: "a", editedAt: now), currentDigest: "b")
                == now)
        #expect(SharedSyncPolicy.outgoing(Record(digest: "a"), currentDigest: "b") == .distantPast)
        #expect(SharedSyncPolicy.outgoing(nil, currentDigest: "b") == .distantPast)
    }

    @Test func stateRoundTripsThroughDisk() throws {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        var state = SharedSyncState()
        state.zones["home"] = SharedSyncState.Zone(
            owner: "_owner", records: ["Tag.t": Record(digest: "a", local: "a")])
        state.parked["home/Tag.t"] = SharedSyncState.Parked(
            profileID: "home", name: "Tag.t", payload: Data([1]), fields: Data([2]))
        try state.save(to: url)
        let loaded = SharedSyncState.load(from: url)
        #expect(loaded.zones == state.zones)
        #expect(loaded.parked == state.parked)
        #expect(loaded.zones["home"]?.known == ["Tag.t"])
    }

    @Test func membersAreOrderedOwnerJoinedInvited() {
        let owner = ProfileMember(id: "o", name: "Zed", role: .owner, status: .joined)
        let joined = ProfileMember(id: "j", name: "Bia", role: .member, status: .joined)
        let invited = ProfileMember(id: "i", name: "Ana", role: .member, status: .invited)
        let other = ProfileMember(id: "k", name: "Carla", role: .member, status: .joined)
        let sorted = [invited, other, owner, joined].sorted(by: SharingCoordinator.order)
        #expect(sorted.map(\.id) == ["o", "j", "k", "i"])
    }
}
