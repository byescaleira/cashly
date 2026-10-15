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

    public var illustration: ProfileIllustration? {
        guard case .illustration(let id) = self else { return nil }
        return ProfileIllustration(id: id)
    }

    public func accessibilityLabel(initials: String) -> String {
        if let illustration {
            return String(appLocalized: "Profile photo with the illustration \(illustration.name)")
        }
        if case .symbol(let name, _) = self {
            return String(
                appLocalized: "Profile photo with the symbol \(ProfileSymbol.name(for: name))")
        }
        return initials.isEmpty
            ? String(appLocalized: "Profile photo")
            : String(appLocalized: "Profile photo with the initials \(initials)")
    }

    public func avatarContent(initials: String) -> Avatar.Content {
        if let illustration { return .image(illustration.image) }
        if case .symbol(let name, _) = self { return .symbol(name) }
        return initials.isEmpty ? .symbol("person.fill") : .monogram(initials)
    }
}
