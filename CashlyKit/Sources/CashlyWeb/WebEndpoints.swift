import Foundation

public struct WebEndpoints: Equatable, Sendable {
    public static let bridgeKey = "CashlyWebBridgeURL"
    public static let websiteKey = "CashlyWebsiteURL"

    public let bridge: URL
    public let page: URL

    public init(bridge: URL, page: URL) {
        self.bridge = bridge
        self.page = page
    }

    public init?(info: [String: Any]) {
        guard let bridge = Self.url(info[Self.bridgeKey]),
            let website = Self.url(info[Self.websiteKey])
        else { return nil }
        self.init(bridge: bridge, page: website.appending(path: "app"))
    }

    public var pageAddress: String {
        let host = page.host() ?? ""
        return host + page.path()
    }

    private static func url(_ value: Any?) -> URL? {
        guard let text = value as? String, !text.isEmpty, let url = URL(string: text),
            url.scheme == "https"
        else { return nil }
        return url
    }
}
