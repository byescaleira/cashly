import Foundation

struct CreateLegacyCommand: AuditCommand {
    static let name = "create-legacy"
    static let usage = "create-legacy <store>"
    let store: URL

    init(arguments: [String]) throws {
        store = try Self.path(arguments)
    }

    func run() async throws -> [String] {
        try LegacyFixture.create(at: store)
        return [LegacyFixture.summary]
    }
}
