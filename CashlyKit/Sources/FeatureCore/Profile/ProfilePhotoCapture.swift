import CashlyDomain
import Foundation

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

public enum ProfilePhotoCapture {
    public static func photo(from text: NSAttributedString, color: String) throws -> ProfilePhoto? {
        if let content = glyphContent(in: text) {
            return .memoji(try ProfilePhotoImage.normalized(content))
        }
        guard let emoji = text.string.reversed().first(where: isEmoji) else { return nil }
        return .emoji(String(emoji), color: color)
    }

    public static func isEmoji(_ character: Character) -> Bool {
        guard let first = character.unicodeScalars.first else { return false }
        return first.properties.isEmojiPresentation
            || (first.properties.isEmoji && character.unicodeScalars.count > 1)
    }

    private static func glyphContent(in text: NSAttributedString) -> Data? {
        var content: Data?
        text.enumerateAttribute(
            .adaptiveImageGlyph, in: NSRange(location: 0, length: text.length)
        ) { value, _, stop in
            guard let glyph = value as? NSAdaptiveImageGlyph else { return }
            content = glyph.imageContent
            stop.pointee = true
        }
        return content
    }
}
