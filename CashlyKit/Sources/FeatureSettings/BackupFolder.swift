import Foundation

public struct BackupFolder: Sendable {
    public static let standard = BackupFolder(
        url: URL.documentsDirectory.appending(path: "Backups", directoryHint: .isDirectory))

    let url: URL
    let keeping: Int

    public init(url: URL, keeping: Int = 5) {
        self.url = url
        self.keeping = keeping
    }

    func save(_ data: Data, on date: Date) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let name = "Cashly " + date.formatted(.iso8601.year().month().day()) + ".json"
        try data.write(to: url.appending(path: name), options: .atomic)
        for old in try files().dropFirst(keeping) { try FileManager.default.removeItem(at: old) }
    }

    func files() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
        )
        .filter { $0.pathExtension == "json" }
        .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
}
