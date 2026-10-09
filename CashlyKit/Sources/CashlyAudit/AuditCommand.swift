import CashlyDomain
import Foundation

protocol AuditCommand {
    static var name: String { get }
    static var usage: String { get }
    @MainActor init(arguments: [String]) throws
    @MainActor func run() async throws -> [String]
}

extension AuditCommand {
    static func path(_ arguments: [String]) throws -> URL {
        guard arguments.count == 1, let path = arguments.first else {
            throw CashlyError.invalidInput("Uso: \(usage)")
        }
        return URL(filePath: path)
    }
}

enum AuditFolder {
    static func make(_ prefix: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(
            path: prefix + "-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

extension YearMonth {
    static func audit(_ rawValue: Int) throws -> YearMonth {
        guard let value = YearMonth(rawValue: rawValue) else {
            throw CashlyError.invalidInput("Competência inválida no diagnóstico.")
        }
        return value
    }
}
