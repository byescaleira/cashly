import Foundation

public struct WidgetSnapshotStore: Sendable {
    public static let fileName = "widget-snapshot.json"

    public static var shared: WidgetSnapshotStore? {
        AppGroup.directory().map(WidgetSnapshotStore.init)
    }

    private let fileURL: URL

    public init(directory: URL) {
        fileURL = directory.appending(path: Self.fileName)
    }

    public func write(_ snapshot: WidgetSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: fileURL, options: .atomic)
    }

    public func read() throws -> WidgetSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WidgetSnapshot.self, from: Data(contentsOf: fileURL))
    }

    public func clear() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }
}
