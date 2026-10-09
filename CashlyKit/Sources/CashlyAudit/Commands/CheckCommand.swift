import CashlyDomain

struct CheckCommand: AuditCommand {
    static let name = "check"
    static let usage = "check"

    init(arguments: [String]) {}

    func run() async throws -> [String] {
        let store = try AuditFolder.make("cashly-check").appending(path: "legacy.store")
        try LegacyFixture.create(at: store)
        let expectations =
            try await AuditExpectations.migration(MigrationReport.measure(store: store))
            + AuditExpectations.sample(SampleReport.measure())
            + AuditExpectations.benchmark(BenchmarkReport.measure(count: 1000))
        let failures = expectations.filter { !$0.passed }
        let lines =
            expectations.map(\.line) + [
                "CHECK passed=\(expectations.count - failures.count) failed=\(failures.count)"
            ]
        guard failures.isEmpty else {
            for line in lines { print(line) }
            throw CashlyError.invalidInput("\(failures.count) verificações falharam.")
        }
        return lines
    }
}
