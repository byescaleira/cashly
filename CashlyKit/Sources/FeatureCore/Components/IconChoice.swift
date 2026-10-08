import SwiftUI

public struct IconChoice: View {
    private let symbol: String
    private let isSelected: Bool
    private let color: Color
    private let action: () -> Void

    public init(symbol: String, isSelected: Bool, color: Color, action: @escaping () -> Void) {
        self.symbol = symbol
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(isSelected ? color : .gray)
                .frame(width: 40, height: 40)
                .background(isSelected ? color.opacity(0.2) : .gray.opacity(0.2), in: .circle)
                .overlay {
                    if isSelected {
                        Circle().stroke(color, lineWidth: 2).frame(width: 45, height: 45)
                    }
                }
                .symbolEffect(
                    .bounce.byLayer, options: .repeat(.continuous).speed(0.1),
                    isActive: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
