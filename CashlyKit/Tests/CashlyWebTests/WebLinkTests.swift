import CashlyWeb
import Foundation
import Testing

struct WebLinkTests {
    private let host = "cashly.byescaleira.com"
    private let session = "ABEiM0RVZneImaq7zN3u_w"
    private let key =
        "BGv4XV_oRZixDKYZnsCczX013NcZX90dx3N6DGcAbvJRuVLyXuwd7tH8oZGDiZBGY1fTFK37fpdguNmvyPOala0"

    @Test func parsesTheVectorLink() throws {
        let vector = try WebVector.load()
        let link = try WebLink(try #require(URL(string: vector.link)), host: host)
        #expect(hexString(link.session) == vector.sessionHex)
        #expect(link.sessionID == vector.sessionID)
        #expect(link.webKey == WebBase64URL.decode(vector.webPublicKey))
    }

    @Test func acceptsTheAppScheme() throws {
        let url = try #require(URL(string: "cashly://link?s=\(session)&k=\(key)"))
        #expect(try WebLink(url, host: host).sessionID == session)
    }

    @Test(arguments: [
        "https://example.com/link?s=ABEiM0RVZneImaq7zN3u_w&k=KEY",
        "http://cashly.byescaleira.com/link?s=ABEiM0RVZneImaq7zN3u_w&k=KEY",
        "https://cashly.byescaleira.com/app?s=ABEiM0RVZneImaq7zN3u_w&k=KEY",
        "https://cashly.byescaleira.com/link?k=KEY",
        "https://cashly.byescaleira.com/link?s=ABEiM0RVZneImaq7&k=KEY",
        "https://cashly.byescaleira.com/link?s=ABEiM0RVZneImaq7zN3u_w&s=ABEiM0RVZneImaq7zN3u_w&k=KEY",
        "https://cashly.byescaleira.com/link?s=ABEiM0RVZneImaq7zN3u_w&k=BGv4XV_oRZixDKYZnsCczX013NcZX90dx3N6DGcAbvJRuVLyXuwd7tH8oZGDiZBGY1fTFK37fpdguNmvyPOalaA",
        "https://cashly.byescaleira.com/link?s=ABEiM0RVZneImaq7zN3u_w&k=AAAA",
        "https://cashly.byescaleira.com/link?s=ABEiM0RVZneImaq7zN3u+w&k=KEY",
    ])
    func rejectsInvalidLinks(text: String) throws {
        let url = try #require(URL(string: text.replacingOccurrences(of: "KEY", with: key)))
        #expect(throws: WebCryptoError.invalidLink) { try WebLink(url, host: host) }
    }

    @Test func recognizesOnlyLinkAddresses() throws {
        #expect(
            WebLink.isLink(
                try #require(URL(string: "https://cashly.byescaleira.com/link")), host: host))
        #expect(
            !WebLink.isLink(
                try #require(URL(string: "https://cashly.byescaleira.com/")), host: host))
        #expect(!WebLink.isLink(try #require(URL(string: "cashly://transactions/new")), host: host))
    }
}
