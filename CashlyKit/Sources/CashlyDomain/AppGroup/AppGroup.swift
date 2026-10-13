import Foundation

public enum AppGroup {
    public static let identifier = "group.com.byescaleira"
    public static let app = "cashly"

    public struct Manifest: Codable, Equatable, Sendable {
        public let app: String
        public let bundleIdentifier: String
        public let version: String
        public let urlScheme: String
        public let files: [String]
        public let updatedAt: Date

        public init(
            app: String, bundleIdentifier: String, version: String, urlScheme: String,
            files: [String], updatedAt: Date = .now
        ) {
            self.app = app
            self.bundleIdentifier = bundleIdentifier
            self.version = version
            self.urlScheme = urlScheme
            self.files = files
            self.updatedAt = updatedAt
        }
    }

    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    public static func directory(for app: String = AppGroup.app) -> URL? {
        guard let container = containerURL else { return nil }
        let directory = container.appending(path: app)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    public static func manifests() -> [Manifest] {
        guard let container = containerURL,
            let apps = try? FileManager.default.contentsOfDirectory(
                at: container, includingPropertiesForKeys: nil)
        else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return apps.compactMap { app in
            guard let data = try? Data(contentsOf: app.appending(path: "manifest.json")) else {
                return nil
            }
            return try? decoder.decode(Manifest.self, from: data)
        }
        .sorted { $0.app < $1.app }
    }

    public static func publish(_ manifest: Manifest) throws {
        guard let directory = directory(for: manifest.app) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(manifest).write(
            to: directory.appending(path: "manifest.json"), options: .atomic)
    }
}
