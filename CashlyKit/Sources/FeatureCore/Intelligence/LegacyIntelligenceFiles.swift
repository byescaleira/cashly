import Foundation

public enum LegacyIntelligenceFiles {
    public static func remove(in directory: URL = .applicationSupportDirectory) {
        try? FileManager.default.removeItem(
            at: directory.appending(path: "Cashly/Intelligence", directoryHint: .isDirectory))
    }
}
