import Foundation

public enum TagSuggestion {
    public static func matches(_ tag: String, in summary: String) -> Bool {
        func words(_ input: String) -> String {
            input.folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: Locale(identifier: "pt_BR")
            )
            .split { !$0.isLetter && !$0.isNumber }.joined(separator: " ")
        }
        let phrase = words(tag)
        return !phrase.isEmpty && (" " + words(summary) + " ").contains(" " + phrase + " ")
    }
}
