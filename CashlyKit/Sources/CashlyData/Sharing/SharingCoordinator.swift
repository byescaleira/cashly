import CashlyDomain
import CloudKit
import Foundation

public actor SharingCoordinator {
    public nonisolated let container: CKContainer
    let database: CashlyDatabase
    let owned: SharedProfileSync
    let joined: SharedProfileSync
    private var listener: Task<Void, Never>?

    public init(
        database: CashlyDatabase, containerIdentifier: String = CashlyDatabase.cloudContainer,
        directory: URL?
    ) {
        let container = CKContainer(identifier: containerIdentifier)
        let registry = SharedZoneRegistry()
        self.container = container
        self.database = database
        owned = SharedProfileSync(
            scope: .owned, container: container, store: database.store,
            stateURL: directory?.appending(path: "owned.json"), registry: registry)
        joined = SharedProfileSync(
            scope: .joined, container: container, store: database.store,
            stateURL: directory?.appending(path: "joined.json"), registry: registry)
    }

    public func start() async {
        guard listener == nil else { return }
        await owned.start()
        await joined.start()
        let feed = database.changes.changes()
        listener = Task { [owned, joined] in
            for await change in feed where !change.isRemote {
                await owned.scheduleScan()
                await joined.scheduleScan()
            }
        }
    }

    public func accountAvailable() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    public func isOwner(of profileID: String) async -> Bool {
        await owned.profileIDs().contains(profileID)
    }

    public func createProfile(_ user: User, copying categories: [CashlyDomain.Category])
        async throws
    {
        await owned.track(SharedZone.id(for: user.id))
        do {
            try await database.repositories(for: nil).users.save(user)
            let scoped = database.repositories(for: user.id)
            for category in categories {
                try await scoped.categories.save(
                    Category(
                        id: UUID().uuidString, user: user, name: category.name,
                        color: category.color, icon: category.icon))
            }
        } catch {
            await owned.forget(user.id)
            throw error
        }
        await owned.create(user.id)
    }

    public func share(profileID: String, title: String) async throws -> CKShare {
        guard await isOwner(of: profileID) else { throw CashlyError.onSave }
        let zoneID = SharedZone.id(for: profileID)
        let database = container.privateCloudDatabase
        if let existing = try await Self.share(in: zoneID, database: database) { return existing }
        _ = try await database.modifyRecordZones(
            saving: [CKRecordZone(zoneID: zoneID)], deleting: [])
        let share = CKShare(recordZoneID: zoneID)
        share[CKShare.SystemFieldKey.title] = title
        share.publicPermission = .none
        let result = try await database.modifyRecords(saving: [share], deleting: [])
        guard let saved = try result.saveResults[share.recordID]?.get() as? CKShare else {
            throw CashlyError.onSave
        }
        CashlyMetrics.logger.info("Sharing created a share for a profile zone")
        return saved
    }

    public func details(profileID: String) async throws -> SharedProfileDetails {
        let isOwner = await isOwner(of: profileID)
        let sync = isOwner ? owned : joined
        let database = isOwner ? container.privateCloudDatabase : container.sharedCloudDatabase
        guard let zoneID = await sync.zoneID(for: profileID),
            let share = try await Self.share(in: zoneID, database: database)
        else {
            return SharedProfileDetails(
                profileID: profileID, isOwner: isOwner, isShared: false, members: [])
        }
        let current = share.currentUserParticipant?.participantID
        let members = share.participants.compactMap { Self.member($0, current: current) }
        return SharedProfileDetails(
            profileID: profileID, isOwner: isOwner, isShared: true,
            members: members.sorted(by: Self.order))
    }

    public func removeMember(_ memberID: String, profileID: String) async throws {
        let database = container.privateCloudDatabase
        guard
            let share = try await Self.share(
                in: SharedZone.id(for: profileID), database: database),
            let participant = share.participants.first(where: { $0.participantID == memberID })
        else { throw CashlyError.missingRecord }
        share.removeParticipant(participant)
        _ = try await database.modifyRecords(saving: [share], deleting: [])
    }

    public func stopSharing(profileID: String) async throws {
        let shareID = SharedZone.shareID(for: SharedZone.id(for: profileID))
        _ = try await container.privateCloudDatabase.modifyRecords(
            saving: [], deleting: [shareID])
    }

    public func leave(profileID: String) async throws {
        guard !(await isOwner(of: profileID)) else { throw CashlyError.onRemove }
        if let zoneID = await joined.zoneID(for: profileID) {
            do {
                _ = try await container.sharedCloudDatabase.modifyRecords(
                    saving: [], deleting: [SharedZone.shareID(for: zoneID)])
            } catch let error as CKError where Self.isGone(error) {}
        }
        await joined.forget(profileID)
    }

    public func deleteForEveryone(profileID: String) async throws {
        guard await isOwner(of: profileID) else { throw CashlyError.onRemove }
        await owned.deleteZone(profileID)
    }

    public func accept(_ metadata: CKShare.Metadata) async throws -> String {
        let zoneID = metadata.share.recordID.zoneID
        guard let profileID = SharedZone.profileID(of: zoneID) else {
            throw CashlyError.missingRecord
        }
        guard metadata.participantRole != .owner else { return profileID }
        _ = try await container.accept(metadata)
        await joined.track(zoneID)
        try? await joined.fetchNow()
        return profileID
    }

    public func refresh() async {
        try? await owned.fetchNow()
        try? await joined.fetchNow()
    }

    public func status() async -> SharingSyncStatus {
        let statuses = [await owned.status(), await joined.status()]
        let phase: SharingSyncStatus.Phase =
            statuses.contains { $0.phase == .syncing }
            ? .syncing : statuses.contains { $0.phase == .failed } ? .failed : .idle
        return SharingSyncStatus(phase: phase, lastSync: statuses.compactMap(\.lastSync).max())
    }

    static func share(in zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> CKShare? {
        do {
            return try await database.record(for: SharedZone.shareID(for: zoneID)) as? CKShare
        } catch let error as CKError where isGone(error) {
            return nil
        }
    }

    static func isGone(_ error: CKError) -> Bool {
        [.unknownItem, .zoneNotFound, .userDeletedZone].contains(error.code)
    }

    static func member(_ participant: CKShare.Participant, current: String?) -> ProfileMember? {
        guard participant.acceptanceStatus != .removed else { return nil }
        let identity = participant.userIdentity
        let name = identity.nameComponents.map {
            PersonNameComponentsFormatter.localizedString(from: $0, style: .default)
        }
        let contact = identity.lookupInfo?.emailAddress ?? identity.lookupInfo?.phoneNumber
        return ProfileMember(
            id: participant.participantID, name: name ?? "", contact: contact,
            role: participant.role == .owner ? .owner : .member,
            status: participant.acceptanceStatus == .accepted ? .joined : .invited,
            isCurrentUser: participant.participantID == current)
    }

    static func order(_ first: ProfileMember, _ second: ProfileMember) -> Bool {
        let firstRank = first.role == .owner ? 0 : first.status == .joined ? 1 : 2
        let secondRank = second.role == .owner ? 0 : second.status == .joined ? 1 : 2
        if firstRank != secondRank { return firstRank < secondRank }
        return first.name.localizedStandardCompare(second.name) == .orderedAscending
    }
}
