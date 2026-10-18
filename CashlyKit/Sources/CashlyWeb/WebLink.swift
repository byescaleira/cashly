import CryptoKit
import Foundation

public struct WebLink: Identifiable, Equatable, Sendable {
    public static let sessionLength = 16
    public static let keyLength = 65
    static let path = "/link"
    static let scheme = "cashly"

    public let session: Data
    public let webKey: Data

    public var id: String { sessionID }
    public var sessionID: String { WebBase64URL.encode(session) }

    public init(session: Data, webKey: Data) throws {
        guard session.count == Self.sessionLength, webKey.count == Self.keyLength,
            (try? P256.KeyAgreement.PublicKey(x963Representation: webKey)) != nil
        else { throw WebCryptoError.invalidLink }
        self.session = session
        self.webKey = webKey
    }

    public init(_ url: URL, host: String) throws {
        guard Self.isLink(url, host: host),
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
            let session = Self.value("s", in: items).flatMap(WebBase64URL.decode),
            let key = Self.value("k", in: items).flatMap(WebBase64URL.decode)
        else { throw WebCryptoError.invalidLink }
        try self.init(session: session, webKey: key)
    }

    public static func isLink(_ url: URL, host: String) -> Bool {
        switch url.scheme?.lowercased() {
        case "https": url.host()?.lowercased() == host.lowercased() && url.path() == path
        case scheme: url.host()?.lowercased() == "link"
        default: false
        }
    }

    private static func value(_ name: String, in items: [URLQueryItem]) -> String? {
        let matches = items.filter { $0.name == name }
        guard let first = matches.first, matches.dropFirst().isEmpty else { return nil }
        return first.value
    }
}
