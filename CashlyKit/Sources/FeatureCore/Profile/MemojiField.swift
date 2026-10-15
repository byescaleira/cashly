import CashlyDesignSystem
import SwiftUI

public struct MemojiField: View {
    @Binding private var isActive: Bool
    private let onInsert: (NSAttributedString) -> Void

    public init(isActive: Binding<Bool>, onInsert: @escaping (NSAttributedString) -> Void) {
        _isActive = isActive
        self.onInsert = onInsert
    }

    public var body: some View {
        MemojiTextInput(isActive: $isActive, onInsert: onInsert)
            .frame(maxWidth: .infinity, minHeight: .rowHeight)
            .overlay(alignment: .leading) {
                Text("Choose a Memoji sticker or an emoji")
                    .foregroundStyle(.secondary)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .accessibilityLabel("Memoji")
            .accessibilityHint("Opens the emoji keyboard with your stickers")
    }
}
