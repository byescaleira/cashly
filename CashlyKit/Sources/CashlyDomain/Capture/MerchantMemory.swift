import Foundation

public struct MerchantMemory: Identifiable, Hashable, Sendable {
    public var key: String
    public var ownerID: String
    public var categoryID: String
    public var summary: String
    public var tagIDs: Set<String>
    public var count: Int

    public var id: String { key }

    public init(
        key: String, ownerID: String, categoryID: String, summary: String,
        tagIDs: Set<String> = [], count: Int = 1
    ) {
        self.key = key
        self.ownerID = ownerID
        self.categoryID = categoryID
        self.summary = summary
        self.tagIDs = tagIDs
        self.count = count
    }

    private static let noise: Set<String> = [
        "ltda", "me", "mei", "eireli", "epp", "sa", "cia", "pag", "pagseguro", "mp",
        "mercadopago", "ifd", "dl", "paypal", "pp", "cielo", "rede", "stone", "getnet", "sumup",
        "pagarme", "picpay", "pos", "ec",
    ]

    public static func key(for merchant: String) -> String {
        let folded = merchant.folding(
            options: [.diacriticInsensitive, .caseInsensitive], locale: nil
        )
        .lowercased()
        let letters = folded.map { $0.isLetter ? $0 : " " }
        let words = String(letters).split(separator: " ").map(String.init)
            .filter { $0.count > 1 && !noise.contains($0) }
        guard !words.isEmpty else {
            return folded.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        }
        return words.joined(separator: " ")
    }
}
