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

    public var photoCaption: String {
        switch draft.photo {
        case .initials: String(appLocalized: "Initials")
        case .symbol(let name, _): ProfileSymbol.name(for: name)
        case .emoji: String(appLocalized: "Emoji")
        case .memoji: String(appLocalized: "Memoji")
        }
    }

    public var memojiFooter: String {
        usesCharacterViewer
            ? String(
                appLocalized:
                    "Click the field to open the Character Viewer and pick a Memoji sticker. A regular emoji works too."
            )
            : String(
                appLocalized:
                    "Your Memoji stickers are on the emoji keyboard: tap the field and swipe to the stickers. A regular emoji works too."
            )
    }

    private var usesCharacterViewer: Bool {
        #if os(macOS)
            true
        #else
            false
        #endif
    }

    public var messagesURL: URL? { URL(string: "sms:") }

    public var tint: Color { Color(hex: photoColor) }

    public var highlightedStyle: PhotoStyle { isPickingMemoji ? .memoji : style }
    public var showsColors: Bool { style != .memoji || memoji?.color != nil }
    public var showsSymbols: Bool { style == .symbol && !isPickingMemoji }
    public var showsMemoji: Bool { style == .memoji || isPickingMemoji }
    public var hasMemoji: Bool { memoji != nil }

    public func preview(for style: PhotoStyle) -> ProfilePhoto {
        switch style {
        case .initials: .initials(color: photoColor)
        case .symbol: .symbol(symbol, color: photoColor)
        case .memoji: memoji ?? .symbol("face.smiling", color: photoColor)
        }
    }

    public func select(_ style: PhotoStyle) {
        switch style {
        case .initials, .symbol:
            isPickingMemoji = false
            self.style = style
            draft.photo = preview(for: style)
        case .memoji:
            if let memoji, self.style != .memoji {
                self.style = .memoji
                draft.photo = memoji
            } else {
                isPickingMemoji = true
            }
        }
    }

    public func select(_ symbol: ProfileSymbol) {
        self.symbol = symbol.rawValue
        select(.symbol)
    }

    public func isSelected(_ symbol: ProfileSymbol) -> Bool {
        style == .symbol && self.symbol == symbol.rawValue
    }

    public func pickMemoji() {
        isPickingMemoji = true
    }

    public func capture(_ text: NSAttributedString) {
        do {
            guard let photo = try ProfilePhotoCapture.photo(from: text, color: photoColor) else {
                return
            }
            memoji = photo
            style = .memoji
            draft.photo = photo
            isPickingMemoji = false
        } catch {
            status.error = error as? CashlyError ?? .onSave
        }
    }

    func adopt(_ photo: ProfilePhoto) {
        style = PhotoStyle(photo)
        switch photo {
        case .symbol(let name, _): symbol = name
        case .emoji, .memoji: memoji = photo
        case .initials: break
        }
        if let color = photo.color { photoColor = color }
    }
}
