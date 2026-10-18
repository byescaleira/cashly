import CashlyData
import CashlyDomain
import CloudKit
import FeatureCore

struct SharingService: ProfileSharing {
    let coordinator: SharingCoordinator

    var container: CKContainer { coordinator.container }

    func accountAvailable() async -> Bool { await coordinator.accountAvailable() }

    func isOwner(of profileID: String) async -> Bool {
        await coordinator.isOwner(of: profileID)
    }

    func createProfile(_ user: User, copying categories: [CashlyDomain.Category]) async throws {
        try await coordinator.createProfile(user, copying: categories)
    }

    func share(profileID: String, title: String) async throws -> CKShare {
        try await coordinator.share(profileID: profileID, title: title)
    }

    func details(profileID: String) async throws -> SharedProfileDetails {
        try await coordinator.details(profileID: profileID)
    }

    func removeMember(_ memberID: String, profileID: String) async throws {
        try await coordinator.removeMember(memberID, profileID: profileID)
    }

    func stopSharing(profileID: String) async throws {
        try await coordinator.stopSharing(profileID: profileID)
    }

    func leave(profileID: String) async throws {
        try await coordinator.leave(profileID: profileID)
    }

    func deleteForEveryone(profileID: String) async throws {
        try await coordinator.deleteForEveryone(profileID: profileID)
    }

    func accept(_ metadata: CKShare.Metadata) async throws -> String {
        try await coordinator.accept(metadata)
    }

    func refresh() async { await coordinator.refresh() }

    func status() async -> SharingSyncStatus { await coordinator.status() }
}
