import Foundation

public struct WebSession: Codable, Identifiable, Equatable, Sendable {
    public static let lifetime: TimeInterval = 24 * 60 * 60
    static let tokenLength = 32

    public let id: String
    public let key: Data
    public let appPublicKey: Data
    public let ownerToken: String
    public let createdAt: Date
    public let expiresAt: Date
    public var lastSentAt: Date?

    public init(
        id: String, key: Data, appPublicKey: Data, ownerToken: String, createdAt: Date
    ) {
        self.id = id
        self.key = key
        self.appPublicKey = appPublicKey
        self.ownerToken = ownerToken
        self.createdAt = createdAt
        expiresAt = createdAt.addingTimeInterval(Self.lifetime)
    }

    public static func pair(with link: WebLink, at date: Date) throws -> WebSession {
        let agreement = try WebCipher.agree(link: link)
        return try WebSession(
            id: link.sessionID, key: agreement.key, appPublicKey: agreement.appPublicKey,
            ownerToken: WebBase64URL.encode(WebRandom.bytes(tokenLength)), createdAt: date)
    }

    public func seal(_ plaintext: Data, nonce: Data? = nil) throws -> WebPackage {
        try WebCipher.seal(
            plaintext, key: key, appPublicKey: appPublicKey, sessionID: id, nonce: nonce)
    }

    public func isExpired(at date: Date) -> Bool {
        date >= expiresAt
    }

    public func remaining(at date: Date) -> TimeInterval {
        max(expiresAt.timeIntervalSince(date), 0)
    }
}
