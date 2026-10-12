import SwiftUI

public struct Chip: View {
    public enum Shape: Sendable {
        case capsule, tag
    }

    private let text: String
    private let color: Color
    private let shape: Shape
    private let font: Font

    public init(_ text: String, color: Color, shape: Shape = .tag, font: Font = .chipLabel) {
        self.text = text
        self.color = color
        self.shape = shape
        self.font = font
    }

    public var body: some View {
        let label = Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, .spaceM)
            .padding(.vertical, shape == .capsule ? .spaceS : .space2XS)
        switch shape {
        case .capsule: label.background(color.opacity(.opacityTint), in: .capsule)
        case .tag: label.background(color.opacity(.opacityTint), in: .rect(cornerRadius: .radiusS))
        }
    }
}
