import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension ProfilePhoto {
    public static func suggested(for id: String) -> ProfilePhoto {
        .initials(color: suggestedColor(for: id).hex)
    }

    public static func suggestedColor(for id: String) -> RetroColor {
        let seed = id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return RetroColor.allCases[seed % RetroColor.allCases.count]
    }

    public var tint: Color { Color(hex: color ?? Self.defaultColor) }

    public func accessibilityLabel(initials: String) -> String {
        switch self {
        case .initials:
            String(appLocalized: "Profile photo with the initials \(initials)")
        case .symbol(let name, _):
            String(appLocalized: "Profile photo with the symbol \(ProfileSymbol.name(for: name))")
        case .emoji(let emoji, _):
            String(appLocalized: "Profile photo with the emoji \(emoji)")
        case .memoji:
            String(appLocalized: "Profile photo with a Memoji")
        }
    }

    @MainActor public func avatarContent(initials: String) -> Avatar.Content {
        switch self {
        case .initials: initials.isEmpty ? .symbol("person.fill") : .monogram(initials)
        case .symbol(let name, _): .symbol(name)
        case .emoji(let emoji, _): .emoji(emoji)
        case .memoji(let data):
            ProfilePhotoImage.image(from: data).map { .image(Image(decorative: $0, scale: 1)) }
                ?? .symbol("person.fill")
        }
    }
}
