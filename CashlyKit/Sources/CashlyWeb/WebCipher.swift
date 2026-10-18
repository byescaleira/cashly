import CryptoKit
import Foundation

public enum WebCipher {
    public static let info = Data("cashly-web:v2".utf8)
    public static let nonceLength = 12
    static let keyLength = 32
    static let tagLength = 16

    public struct Agreement: Sendable {
        public let sharedSecret: Data
        public let key: Data
        public let appPublicKey: Data
    }

    public static func agree(appPrivateKey: Data? = nil, link: WebLink) throws -> Agreement {
        let appKey =
            try appPrivateKey.map { try P256.KeyAgreement.PrivateKey(rawRepresentation: $0) }
            ?? P256.KeyAgreement.PrivateKey()
        let webKey = try P256.KeyAgreement.PublicKey(x963Representation: link.webKey)
        let shared = try appKey.sharedSecretFromKeyAgreement(with: webKey)
        let key = shared.hkdfDerivedSymmetricKey(
            using: SHA256.self, salt: link.session, sharedInfo: info, outputByteCount: keyLength)
        return Agreement(
            sharedSecret: shared.withUnsafeBytes { Data($0) },
            key: key.withUnsafeBytes { Data($0) },
            appPublicKey: appKey.publicKey.x963Representation)
    }

    public static func seal(
        _ plaintext: Data, key: Data, appPublicKey: Data, sessionID: String, nonce: Data? = nil
    ) throws -> WebPackage {
        let nonceData = try nonce ?? WebRandom.bytes(nonceLength)
        let box = try AES.GCM.seal(
            plaintext, using: SymmetricKey(data: key), nonce: AES.GCM.Nonce(data: nonceData),
            authenticating: Data(sessionID.utf8))
        return WebPackage(
            appKey: appPublicKey, nonce: nonceData, ciphertext: box.ciphertext + box.tag)
    }

    public static func open(_ package: WebPackage, key: Data, sessionID: String) throws -> Data {
        guard package.v == WebPackage.version,
            let nonce = Data(base64Encoded: package.nonce),
            let combined = Data(base64Encoded: package.ciphertext),
            combined.count >= tagLength
        else { throw WebCryptoError.invalidPackage }
        let box = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: nonce), ciphertext: combined.dropLast(tagLength),
            tag: combined.suffix(tagLength))
        return try AES.GCM.open(
            box, using: SymmetricKey(data: key), authenticating: Data(sessionID.utf8))
    }
}
