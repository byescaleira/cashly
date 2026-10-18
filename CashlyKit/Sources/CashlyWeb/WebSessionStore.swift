import Foundation
import Security

public protocol WebSessionStoring: Sendable {
    func load() -> [WebSession]
    func save(_ sessions: [WebSession]) throws
}

public struct KeychainWebSessionStore: WebSessionStoring {
    public static let standard = KeychainWebSessionStore()

    private let service: String
    private let account: String

    public init(service: String = "com.byescaleira.cashly.web", account: String = "sessions") {
        self.service = service
        self.account = account
    }

    public func load() -> [WebSession] {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data
        else { return [] }
        return (try? JSONDecoder().decode([WebSession].self, from: data)) ?? []
    }

    public func save(_ sessions: [WebSession]) throws {
        SecItemDelete(baseQuery as CFDictionary)
        guard !sessions.isEmpty else { return }
        let data = try JSONEncoder().encode(sessions)
        var item = baseQuery
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw WebSessionStoreError.keychain(status) }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }
}

public enum WebSessionStoreError: Error, Equatable, Sendable {
    case keychain(OSStatus)
}
