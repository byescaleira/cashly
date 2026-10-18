import CashlyDomain
import CloudKit
import FeatureCore
import Foundation

actor PreviewSharing: ProfileSharing {
    nonisolated var container: CKContainer { CKContainer(identifier: "iCloud.cashly") }

    func accountAvailable() async -> Bool { true }
    func isOwner(of profileID: String) async -> Bool { true }
    func createProfile(_ user: User, copying categories: [CashlyDomain.Category]) async throws {}
    func share(profileID: String, title: String) async throws -> CKShare {
        CKShare(recordZoneID: CKRecordZone.ID(zoneName: "profile." + profileID))
    }
    func details(profileID: String) async throws -> SharedProfileDetails {
        SharedProfileDetails(
            profileID: profileID, isOwner: true, isShared: true,
            members: [
                ProfileMember(
                    id: "me", name: "Rafael Escaleira", role: .owner, status: .joined,
                    isCurrentUser: true),
                ProfileMember(
                    id: "ana", name: "Ana Souza", contact: "ana@example.com", role: .member,
                    status: .joined),
                ProfileMember(
                    id: "leo", name: "", contact: "leo@example.com", role: .member,
                    status: .invited),
            ])
    }
    func removeMember(_ memberID: String, profileID: String) async throws {}
    func stopSharing(profileID: String) async throws {}
    func leave(profileID: String) async throws {}
    func deleteForEveryone(profileID: String) async throws {}
    func accept(_ metadata: CKShare.Metadata) async throws -> String { "" }
    func refresh() async {}
    func status() async -> SharingSyncStatus {
        SharingSyncStatus(phase: .idle, lastSync: .now)
    }
}
