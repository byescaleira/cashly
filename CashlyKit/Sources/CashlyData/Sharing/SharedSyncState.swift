import CloudKit
import Foundation

struct SharedSyncState: Codable, Sendable {
    struct Record: Codable, Equatable, Sendable {
        var digest: String?
        var local: String?
        var fields: Data?
        var editedAt: Date?
    }

    struct Zone: Codable, Equatable, Sendable {
        var owner: String
        var records: [String: Record] = [:]

        var confirmed: [String: String] { records.compactMapValues(\.digest) }
        var known: Set<String> { Set(confirmed.keys) }
    }

    struct Parked: Codable, Equatable, Sendable {
        var profileID: String
        var name: String
        var payload: Data
        var fields: Data
    }

    var engine: CKSyncEngine.State.Serialization?
    var zones: [String: Zone] = [:]
    var parked: [String: Parked] = [:]

    static func load(from url: URL?) -> SharedSyncState {
        guard let url, let data = try? Data(contentsOf: url),
            let state = try? JSONDecoder().decode(SharedSyncState.self, from: data)
        else { return SharedSyncState() }
        return state
    }

    func save(to url: URL?) throws {
        guard let url else { return }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(self).write(to: url, options: .atomic)
    }
}
