import CashlyDesignSystem
import SwiftUI

public struct PremiumColorPicker: View {
    @Binding private var hex: String
    private let colors: [PremiumColor]
    private let isLocked: Bool
    private let onLocked: () -> Void

    public init(
        colors: [PremiumColor], hex: Binding<String>, isLocked: Bool,
        onLocked: @escaping () -> Void
    ) {
        self.colors = colors
        _hex = hex
        self.isLocked = isLocked
        self.onLocked = onLocked
    }

    public var body: some View {
        let selection = PremiumColor(hex: hex)
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 44, maximum: 44), spacing: .spaceM)],
            spacing: .spaceM
        ) {
            ForEach(colors) { color in
                Button {
                    if isLocked { onLocked() } else { hex = color.hex }
                } label: {
                    Circle()
                        .fill(color.color.gradient)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(.white)
                            } else if color == selection {
                                Image(systemName: "checkmark")
                                    .font(.footnote.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay {
                            if color == selection && !isLocked {
                                Circle().stroke(color.color, lineWidth: 2)
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.name)
                .accessibilityValue(isLocked ? Text("Locked") : Text(verbatim: ""))
                .accessibilityAddTraits(color == selection && !isLocked ? .isSelected : [])
            }
        }
        .padding(.vertical, .spaceS)
        .sensoryFeedback(.selection, trigger: hex)
    }
}
