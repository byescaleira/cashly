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

    public static func cloud(container: String) -> BackupFolder? {
        FileManager.default.url(forUbiquityContainerIdentifier: container).map {
            BackupFolder(url: $0.appending(path: "Documents/Backups", directoryHint: .isDirectory))
        }
    }

    static func name(on date: Date) -> String {
        "Cashly " + date.formatted(.iso8601.year().month().day()) + ".json"
    }

    func save(_ data: Data, on date: Date) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        let file = url.appending(path: Self.name(on: date))
        try Self.coordinate(writing: file, options: .forReplacing) {
            try data.write(to: $0, options: .atomic)
        }
        for old in try files().dropFirst(keeping) {
            try Self.coordinate(writing: old, options: .forDeleting) {
                try FileManager.default.removeItem(at: $0)
            }
        }
    }

    func files() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            .compactMap(Self.logicalFile)
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    static func read(_ file: URL) throws -> Data {
        try? FileManager.default.startDownloadingUbiquitousItem(at: file)
        var result: Result<Data, any Error> = .failure(CocoaError(.fileReadUnknown))
        var coordination: NSError?
        NSFileCoordinator().coordinate(readingItemAt: file, options: [], error: &coordination) {
            coordinated in
            result = Result { try Data(contentsOf: coordinated) }
        }
        if let coordination { throw coordination }
        return try result.get()
    }

    private static func logicalFile(_ file: URL) -> URL? {
        let name = file.lastPathComponent
        let placeholder = ".icloud"
        if name.hasPrefix("."), name.hasSuffix(".json" + placeholder) {
            return file.deletingLastPathComponent().appending(
                path: String(name.dropFirst().dropLast(placeholder.count)))
        }
        return !name.hasPrefix(".") && file.pathExtension == "json" ? file : nil
    }

    private static func coordinate(
        writing file: URL, options: NSFileCoordinator.WritingOptions,
        _ body: (URL) throws -> Void
    ) throws {
        var failure: (any Error)?
        var coordination: NSError?
        NSFileCoordinator().coordinate(writingItemAt: file, options: options, error: &coordination)
        {
            do { try body($0) } catch { failure = error }
        }
        if let coordination { throw coordination }
        if let failure { throw failure }
    }
}
