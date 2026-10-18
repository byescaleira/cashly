import CryptoKit
import Foundation

struct SharedRecord: Hashable, Sendable {
    enum Kind: String, CaseIterable, Sendable {
        case profile = "Profile"
        case category = "Category"
        case tag = "Tag"
        case budget = "Budget"
        case transaction = "Transaction"
        case participant = "Participant"
    }

    struct Key: Hashable, Sendable {
        let kind: Kind
        let id: String

        var name: String { kind.rawValue + "." + id }

        init(kind: Kind, id: String) {
            self.kind = kind
            self.id = id
        }

        init?(name: String) {
            guard let dot = name.firstIndex(of: "."),
                let kind = Kind(rawValue: String(name[..<dot]))
            else { return nil }
            let id = String(name[name.index(after: dot)...])
            guard !id.isEmpty else { return nil }
            self.init(kind: kind, id: id)
        }
    }

    let key: Key
    let payload: Data

    init(key: Key, payload: Data) {
        self.key = key
        self.payload = payload
    }

    init<Row: Encodable>(kind: Kind, id: String, row: Row) throws {
        key = Key(kind: kind, id: id)
        payload = try Self.encoder.encode(row)
    }

    var name: String { key.name }
    var digest: String { Self.digest(of: payload) }

    func decode<Row: Decodable>(_ type: Row.Type) throws -> Row {
        try JSONDecoder().decode(type, from: payload)
    }

    static func digest(of payload: Data) -> String {
        SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
