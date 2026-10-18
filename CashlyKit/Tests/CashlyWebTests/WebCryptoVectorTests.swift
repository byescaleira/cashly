import CashlyWeb
import CryptoKit
import Foundation
import Testing

struct WebCryptoVectorTests {
    private let host = "cashly.byescaleira.com"

    @Test func derivesTheSharedSecretAndKeyOfTheVector() throws {
        let vector = try WebVector.load()
        let link = try WebLink(try #require(URL(string: vector.link)), host: host)
        let agreement = try WebCipher.agree(
            appPrivateKey: hexData(vector.appPrivateKeyHex), link: link)
        #expect(hexString(agreement.sharedSecret) == vector.sharedSecretHex)
        #expect(hexString(agreement.key) == vector.keyHex)
        #expect(agreement.appPublicKey == WebBase64URL.decode(vector.appPublicKey))
    }

    @Test func sealingWithTheVectorNonceReproducesThePackage() throws {
        let vector = try WebVector.load()
        let package = try WebCipher.seal(
            Data(vector.plaintext.utf8), key: hexData(vector.keyHex),
            appPublicKey: try #require(WebBase64URL.decode(vector.appPublicKey)),
            sessionID: vector.sessionID,
            nonce: Data(base64Encoded: vector.package.nonce))
        #expect(package == vector.package)
    }

    @Test func opensTheVectorPackage() throws {
        let vector = try WebVector.load()
        let plaintext = try WebCipher.open(
            vector.package, key: hexData(vector.keyHex), sessionID: vector.sessionID)
        #expect(String(decoding: plaintext, as: UTF8.self) == vector.plaintext)
        let snapshot = try JSONDecoder().decode(WebSnapshot.self, from: plaintext)
        #expect(snapshot.profile.name == "Dana")
        #expect(snapshot.month.pace == .onTrack)
    }

    @Test func rejectsAPackageForAnotherSession() throws {
        let vector = try WebVector.load()
        #expect(throws: (any Error).self) {
            try WebCipher.open(
                vector.package, key: hexData(vector.keyHex), sessionID: "AAAAAAAAAAAAAAAAAAAAAA")
        }
    }

    @Test func theBrowserOpensWhatANewSessionSeals() throws {
        let vector = try WebVector.load()
        let link = try WebLink(try #require(URL(string: vector.link)), host: host)
        let session = try WebSession.pair(with: link, at: .now)
        let package = try session.seal(Data(vector.plaintext.utf8))
        let browser = try P256.KeyAgreement.PrivateKey(
            rawRepresentation: hexData(vector.webPrivateKeyHex))
        let appKey = try P256.KeyAgreement.PublicKey(
            x963Representation: try #require(Data(base64Encoded: package.appKey)))
        let key = try browser.sharedSecretFromKeyAgreement(with: appKey)
            .hkdfDerivedSymmetricKey(
                using: SHA256.self, salt: link.session, sharedInfo: WebCipher.info,
                outputByteCount: 32)
        let opened = try WebCipher.open(
            package, key: key.withUnsafeBytes { Data($0) }, sessionID: vector.sessionID)
        #expect(String(decoding: opened, as: UTF8.self) == vector.plaintext)
        #expect(package.v == 2)
    }
}
