import Foundation

struct ProfileCommand: AuditCommand {
    static let name = "profile"
    static let usage = "profile <benchmark.store>"
    let store: URL

    init(arguments: [String]) throws {
        store = try Self.path(arguments)
    }

    func run() async throws -> [String] {
        try await ProfileReport.measure(store: store)
    }
}
