import CashlyDomain
import FeatureCore
import Foundation
import SwiftUI

extension UserEditorModel {
    public var initials: String { User.initials(of: draft.name) }

    public var displayName: String {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? String(appLocalized: "New Profile") : name
    }

    public var photoCaption: String { PhotoStyle(draft.photo).title }

    public var captionTint: Color { draft.photo.tint }

    public var tint: Color { Color(hex: photoColor) }
    public var showsColors: Bool { style != .illustration }
    public var showsSymbols: Bool { style == .symbol }
    public var showsIllustrations: Bool { style == .illustration }
    public var illustrationSections: [ProfileIllustration.Section] {
        ProfileIllustration.Section.allCases.filter { !$0.illustrations.isEmpty }
    }

    public func preview(for style: PhotoStyle) -> ProfilePhoto {
        switch style {
        case .initials: .initials(color: photoColor)
        case .symbol: .symbol(symbol, color: photoColor)
        case .illustration: illustration.map(ProfilePhoto.illustration) ?? .default
        }
    }

    public func select(_ style: PhotoStyle) {
        self.style = style
        draft.photo = preview(for: style)
    }

    public func select(_ symbol: ProfileSymbol) {
        self.symbol = symbol.rawValue
        select(.symbol)
    }

    public func isSelected(_ symbol: ProfileSymbol) -> Bool {
        style == .symbol && self.symbol == symbol.rawValue
    }

    public func isSelected(_ illustration: ProfileIllustration) -> Bool {
        draft.photo == .illustration(illustration.id)
    }

    public func access(to section: ProfileIllustration.Section, in shop: ShopAccess) -> PackAccess {
        shop.access(to: section.shopItem)
    }

    public func choose(_ illustration: ProfileIllustration, in shop: ShopAccess) {
        if let item = shop.access(to: illustration.shopItem).lockedItem {
            shop.open(item)
            return
        }
        self.illustration = illustration.id
        select(.illustration)
    }

    func adopt(_ photo: ProfilePhoto) {
        style = PhotoStyle(photo)
        switch photo {
        case .symbol(let name, _): symbol = name
        case .illustration(let id): illustration = id
        case .initials: break
        }
        if let color = photo.color { photoColor = color }
    }
}
