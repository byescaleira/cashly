import CashlyDomain
import Foundation
import Testing

struct AppGroupTests {
    @Test func manifestRoundTrips() throws {
        let manifest = AppGroup.Manifest(
            app: "cashly", bundleIdentifier: "com.byescaleira.cashly", version: "1.0 (1)",
            urlScheme: "cashly", files: [WidgetSnapshotStore.fileName],
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(manifest)
        #expect(try decoder.decode(AppGroup.Manifest.self, from: data) == manifest)
        #expect(AppGroup.identifier == "group.com.byescaleira")
        #expect(AppGroup.app == "cashly")
    }
}
