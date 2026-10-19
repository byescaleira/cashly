import CashlyDomain
import CloudKit
import FeatureCore
import Foundation
import Testing

@MainActor
struct SharingModelTests {
    let home = User(id: "home", name: "Home")

    @Test func creatingAProfileOpensTheInvite() async throws {
        let service = FakeSharing()
        let model = SharingModel(service: service)
        let category = Category(id: "c", user: home, name: "Food", color: "C2602A", icon: "cart")
        try await model.create(home, copying: [category])
        #expect(await service.created == ["home": 1])
        #expect(model.inviting?.id == "home")
        #expect(model.inviting?.isShared == true)
    }

    @Test func ownerMessagesFollowWhoJoined() async throws {
        let service = FakeSharing()
        let model = SharingModel(service: service)
        await model.checkAccount()
        await model.load(profileID: "home")
        #expect(model.heroMessage(for: home).contains("Only you"))
        #expect(model.canInvite(to: home))
        #expect(!model.canInvite(to: User(id: "other", name: "Other")))
        #expect(model.members(of: User(id: "other", name: "Other")).isEmpty)
        await service.set(members: [FakeSharing.owner, FakeSharing.ana, FakeSharing.invited])
        await model.load(profileID: "home")
        #expect(model.heroMessage(for: home).contains("1"))
        #expect(model.heroPeople == 1)
        #expect(model.exitActions(for: home) == [.stopSharing(home), .deleteForEveryone(home)])
        #expect(model.membersFooter.contains("Swipe"))
        #expect(model.members.map(\.id) == ["me", "ana", "leo"])
        #expect(model.canRemove(FakeSharing.ana))
        #expect(!model.canRemove(FakeSharing.owner))
        #expect(model.name(of: FakeSharing.owner) == "You")
        #expect(model.name(of: FakeSharing.invited) == "leo@example.com")
        #expect(
            model.name(of: ProfileMember(id: "x", name: "", role: .member, status: .joined))
                == "Person who joined")
        #expect(
            model.name(of: ProfileMember(id: "y", name: "", role: .member, status: .invited))
                == "Invited person")
        #expect(model.badge(of: FakeSharing.invited) == "Invited")
    }

    @Test func membersSeeWhoSharedWithThem() async throws {
        let service = FakeSharing(isOwner: false)
        await service.set(members: [FakeSharing.ana.asOwner, FakeSharing.me])
        let model = SharingModel(service: service)
        await model.load(profileID: "home")
        #expect(model.heroMessage(for: home).contains("Ana Souza"))
        #expect(model.exitActions(for: home) == [.leave(home)])
        #expect(!model.canInvite(to: home))
        #expect(!model.canRemove(FakeSharing.me))
    }

    @Test func confirmationsCallTheServiceAndClose() async throws {
        let service = FakeSharing()
        await service.set(members: [FakeSharing.owner, FakeSharing.ana])
        let model = SharingModel(service: service)
        await model.load(profileID: "home")
        model.confirmation = .removeMember(FakeSharing.ana, home)
        await model.confirm()
        #expect(await service.removed == ["ana"])
        #expect(model.confirmation == nil)
        model.confirmation = .leave(home)
        await model.confirm()
        #expect(await service.left == ["home"])
        #expect(model.details == nil)
    }

    @Test func leavingAndDeletingAreDifferentCalls() async throws {
        let service = FakeSharing()
        let model = SharingModel(service: service)
        model.confirmation = .deleteForEveryone(home)
        await model.confirm()
        #expect(await service.deleted == ["home"])
        #expect(await service.left.isEmpty)
    }

    @Test func openingAnotherProfileNeverKeepsTheOldDetails() async throws {
        let service = FakeSharing(isOwner: false)
        let model = SharingModel(service: service)
        await model.load(profileID: "joined")
        #expect(model.details?.profileID == "joined")
        await service.failDetails()
        await model.load(profileID: "mine")
        #expect(model.details == nil)
        #expect(model.loadError != nil)
        #expect(model.membersNotice != nil)
        #expect(model.exitActions(for: User(id: "mine", name: "Mine")).isEmpty)
    }

    @Test func pendingInvitesAreCountedApart() async throws {
        let service = FakeSharing()
        await service.set(members: [FakeSharing.owner, FakeSharing.invited])
        let model = SharingModel(service: service)
        await model.load(profileID: "home")
        #expect(model.heroMessage(for: home).contains("Waiting"))
        #expect(model.heroPeople == 1)
        #expect(model.exitActions(for: home) == [.stopSharing(home), .deleteForEveryone(home)])
    }

    @Test func nobodyInvitesBeforeOwnershipIsKnown() async throws {
        let model = SharingModel(service: FakeSharing())
        await model.checkAccount()
        #expect(!model.canInvite(to: home))
    }

    @Test func turnedOffSharingExplainsInsteadOfSpinning() async throws {
        let model = SharingModel()
        await model.load(profileID: "home")
        #expect(!model.isLoadingMembers)
        #expect(model.membersNotice != nil)
        #expect(model.exitActions(for: home).isEmpty)
        model.markUnavailable()
        #expect(model.acceptError == nil)
    }

    @Test func failuresKeepTheConfirmationOpen() async throws {
        let service = FakeSharing(failure: CKError(.networkUnavailable))
        let model = SharingModel(service: service)
        model.confirmation = .stopSharing(home)
        await model.confirm()
        #expect(model.confirmation != nil)
        #expect(model.error != nil)
    }

    @Test func attachingTurnsSharingOn() async {
        let model = SharingModel()
        #expect(!model.isEnabled)
        #expect(!model.canCreate)
        await model.attach(FakeSharing())
        #expect(model.isEnabled)
        #expect(model.canCreate)
    }

    @Test func syncTextsFollowTheStatus() async {
        let service = FakeSharing()
        let model = SharingModel(service: service)
        await model.load(profileID: "home")
        #expect(model.syncTitle == "Waiting for iCloud")
        await service.set(status: SharingSyncStatus(phase: .idle, lastSync: .now))
        await model.load(profileID: "home")
        #expect(model.syncTitle == "Up to date")
        await service.set(status: SharingSyncStatus(phase: .failed, lastSync: .now))
        await model.load(profileID: "home")
        #expect(model.syncTitle == "Couldn't sync")
    }
}

actor FakeSharing: ProfileSharing {
    static let me = ProfileMember(
        id: "me", name: "Rafael", role: .member, status: .joined, isCurrentUser: true)
    static let owner = ProfileMember(
        id: "me", name: "Rafael", role: .owner, status: .joined, isCurrentUser: true)
    static let ana = ProfileMember(
        id: "ana", name: "Ana Souza", contact: "ana@example.com", role: .member, status: .joined)
    static let invited = ProfileMember(
        id: "leo", name: "", contact: "leo@example.com", role: .member, status: .invited)

    let isOwner: Bool
    let failure: (any Error)?
    var members: [ProfileMember] = [owner]
    var currentStatus = SharingSyncStatus()
    var created: [String: Int] = [:]
    var removed: [String] = []
    var left: [String] = []
    var deleted: [String] = []
    var failsDetails = false

    func failDetails() { failsDetails = true }

    init(isOwner: Bool = true, failure: (any Error)? = nil) {
        self.isOwner = isOwner
        self.failure = failure
    }

    nonisolated var container: CKContainer { CKContainer(identifier: "iCloud.cashly") }

    func set(members: [ProfileMember]) { self.members = members }
    func set(status: SharingSyncStatus) { currentStatus = status }

    func accountAvailable() async -> Bool { true }
    func isOwner(of profileID: String) async -> Bool { isOwner }
    func createProfile(_ user: User, copying categories: [CashlyDomain.Category]) async throws {
        if let failure { throw failure }
        created[user.id] = categories.count
    }
    func share(profileID: String, title: String) async throws -> CKShare {
        throw CashlyError.onSave
    }
    func details(profileID: String) async throws -> SharedProfileDetails {
        if failsDetails { throw CKError(.networkUnavailable) }
        return SharedProfileDetails(
            profileID: profileID, isOwner: isOwner, isShared: members.count > 1, members: members)
    }
    func removeMember(_ memberID: String, profileID: String) async throws {
        if let failure { throw failure }
        removed.append(memberID)
    }
    func stopSharing(profileID: String) async throws {
        if let failure { throw failure }
    }
    func leave(profileID: String) async throws {
        if let failure { throw failure }
        left.append(profileID)
    }
    func deleteForEveryone(profileID: String) async throws {
        if let failure { throw failure }
        deleted.append(profileID)
    }
    func accept(_ metadata: CKShare.Metadata) async throws -> String { "" }
    func refresh() async {}
    func status() async -> SharingSyncStatus { currentStatus }
}

extension ProfileMember {
    var asOwner: ProfileMember {
        ProfileMember(id: id, name: name, contact: contact, role: .owner, status: .joined)
    }
}
