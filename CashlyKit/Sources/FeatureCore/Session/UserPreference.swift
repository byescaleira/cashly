import Foundation

public struct UserPreference: Sendable {
    public static let standard = UserPreference(isEnabled: true)
    public static let disabled = UserPreference(isEnabled: false)

    private let isEnabled: Bool
    private let key = "cashly.user.id"
    private let legacyKey = "cashly.user"

    public var selectedUserID: String? {
        guard isEnabled else { return nil }
        if let id = UserDefaults.standard.string(forKey: key) { return id }
        return UserDefaults.standard.data(forKey: legacyKey).flatMap {
            try? JSONDecoder().decode(LegacyUser.self, from: $0).id
        }
    }

    public func save(_ userID: String) {
        guard isEnabled else { return }
        UserDefaults.standard.set(userID, forKey: key)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }

    private struct LegacyUser: Decodable {
        let id: String
    }
}
