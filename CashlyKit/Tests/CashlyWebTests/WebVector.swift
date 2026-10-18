import CashlyWeb
import Foundation
import Testing

struct WebVector: Decodable {
    let webPrivateKeyHex: String
    let webPublicKey: String
    let appPrivateKeyHex: String
    let appPublicKey: String
    let sessionHex: String
    let sessionID: String
    let link: String
    let sharedSecretHex: String
    let keyHex: String
    let package: WebPackage
    let plaintext: String

    static func load() throws -> WebVector {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "docs/web-test-vector-v2.json")
        return try JSONDecoder().decode(WebVector.self, from: Data(contentsOf: url))
    }
}

func hexData(_ text: String) throws -> Data {
    var data = Data()
    var index = text.startIndex
    while index < text.endIndex {
        let next = text.index(index, offsetBy: 2)
        data.append(try #require(UInt8(text[index..<next], radix: 16)))
        index = next
    }
    return data
}

func hexString(_ data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
}
