import Foundation

public struct WebPackage: Codable, Equatable, Sendable {
    public static let version = 2

    public let v: Int
    public let appKey: String
    public let nonce: String
    public let ciphertext: String

    public init(appKey: Data, nonce: Data, ciphertext: Data) {
        v = Self.version
        self.appKey = appKey.base64EncodedString()
        self.nonce = nonce.base64EncodedString()
        self.ciphertext = ciphertext.base64EncodedString()
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}
