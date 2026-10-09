import CashlyDomain
import Darwin

@main
struct CashlyAudit {
    static let commands: [any AuditCommand.Type] = [
        CheckCommand.self, CreateLegacyCommand.self, MigrationAuditCommand.self,
        PreviewCommand.self, BenchmarkCommand.self, ProfileCommand.self,
    ]

    @MainActor static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let name = arguments.first else {
            print(commands.map { $0.usage }.joined(separator: " | "))
            return
        }
        do {
            guard let command = commands.first(where: { $0.name == name }) else {
                throw CashlyError.invalidInput("Comando desconhecido: \(name).")
            }
            for line in try await execute(command, arguments: Array(arguments.dropFirst())) {
                print(line)
            }
        } catch {
            print("DIAGNOSTIC_FAILED: \(error.localizedDescription)")
            exit(1)
        }
    }

    @MainActor private static func execute<Command: AuditCommand>(
        _ type: Command.Type, arguments: [String]
    ) async throws -> [String] {
        try await Command(arguments: arguments).run()
    }
}
