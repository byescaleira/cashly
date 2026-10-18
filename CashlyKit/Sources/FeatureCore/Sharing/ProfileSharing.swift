import CashlyDomain
import CloudKit

public protocol ProfileSharing: Sendable {
    var container: CKContainer { get }
    func accountAvailable() async -> Bool
    func isOwner(of profileID: String) async -> Bool
    func createProfile(_ user: User, copying categories: [CashlyDomain.Category]) async throws
    func share(profileID: String, title: String) async throws -> CKShare
    func details(profileID: String) async throws -> SharedProfileDetails
    func removeMember(_ memberID: String, profileID: String) async throws
    func stopSharing(profileID: String) async throws
    func leave(profileID: String) async throws
    func deleteForEveryone(profileID: String) async throws
    func accept(_ metadata: CKShare.Metadata) async throws -> String
    func refresh() async
    func status() async -> SharingSyncStatus
}
