import Foundation

struct MigrationAuditCommand: AuditCommand {
    static let name = "audit"
    static let usage = "audit <store>"
    let store: URL

    init(arguments: [String]) throws {
        store = try Self.path(arguments)
    }

    func run() async throws -> [String] {
        try await MigrationReport.measure(store: store).lines
    }
}
