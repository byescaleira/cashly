import Foundation

extension SymbolCategory {
    public func symbols(matching query: String) -> [String] {
        let words = Self.fold(query).split(separator: " ").map(String.init)
        guard !words.isEmpty, !Self.matches(words, terms: Self.fold(name).split(separator: " "))
        else { return symbols }
        return symbols.filter { symbol in
            let tokens = symbol.split(separator: ".").map(String.init)
            let terms = tokens.compactMap { Self.keywords[$0] }.flatMap {
                Self.fold($0).split(separator: " ")
            }
            return words.allSatisfy { word in
                tokens.contains(word) || terms.contains { $0.hasPrefix(word) }
            }
        }
    }

    public static func label(for symbol: String) -> String {
        let word = symbol.split(separator: ".").lazy
            .compactMap { keywords[String($0)]?.split(separator: " ").first }
            .first
        return word.map { $0.prefix(1).uppercased() + $0.dropFirst() } ?? symbol
    }

    private static func matches(_ words: [String], terms: [Substring]) -> Bool {
        words.allSatisfy { word in terms.contains { $0.hasPrefix(word) } }
    }

    private static func fold(_ text: String) -> String {
        text.folding(
            options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
    }
}
