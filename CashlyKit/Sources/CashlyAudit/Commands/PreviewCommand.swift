struct PreviewCommand: AuditCommand {
    static let name = "preview"
    static let usage = "preview"

    init(arguments: [String]) {}

    func run() async throws -> [String] {
        try await SampleReport.measure().lines
    }
}
