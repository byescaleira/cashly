struct BenchmarkCommand: AuditCommand {
    static let name = "benchmark"
    static let usage = "benchmark <count>"
    let count: Int

    init(arguments: [String]) {
        count = arguments.first.flatMap(Int.init) ?? 1000
    }

    func run() async throws -> [String] {
        try await BenchmarkReport.measure(count: count).lines
    }
}
