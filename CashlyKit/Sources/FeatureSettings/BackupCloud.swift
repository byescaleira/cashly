import CashlyDomain
import Foundation

public struct BackupCloud: Sendable {
    public static let unavailable = BackupCloud { nil }

    let resolve: @Sendable () async -> BackupFolder?

    public init(resolve: @escaping @Sendable () async -> BackupFolder?) {
        self.resolve = resolve
    }

    public static func container(_ identifier: String) -> BackupCloud {
        BackupCloud {
            await Task.detached(priority: .utility) {
                BackupFolder.cloud(container: identifier)
            }.value
        }
    }
}

public enum BackupPlace: String, Sendable {
    case device, iCloud
}

public enum CloudDriveState: Sendable {
    case checking, available, unavailable

    var title: String {
        switch self {
        case .checking: String(appLocalized: "Checking")
        case .available: String(appLocalized: "Available")
        case .unavailable: String(appLocalized: "Unavailable")
        }
    }
}

public struct SavedBackup: Identifiable, Hashable, Sendable {
    public let url: URL
    public var id: URL { url }

    var title: String {
        let name = url.deletingPathExtension().lastPathComponent
        let day = name.replacingOccurrences(of: "Cashly ", with: "")
        guard let date = try? Date(day, strategy: .iso8601.year().month().day()) else {
            return name
        }
        var style = Date.FormatStyle(date: .long, time: .omitted, locale: .app)
        style.timeZone = .gmt
        return date.formatted(style)
    }
}
