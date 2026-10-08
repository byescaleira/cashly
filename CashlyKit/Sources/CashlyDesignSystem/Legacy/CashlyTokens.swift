import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

public indirect enum CashlySpacing {
    case zero, extraSmall, small, medium, large, extraLarge
    case negative(CashlySpacing)
    public var value: CGFloat {
        switch self {
        case .zero: 0
        case .extraSmall: 4
        case .small: 8
        case .medium: 16
        case .large: 24
        case .extraLarge: 32
        case .negative(let spacing): -spacing.value
        }
    }
}
public enum CashlyColor {
    case primary, secondary, text, textSecondary, disabled, error, info, white, background, success,
        warning
    case color(Color)
    case hex(String?)
    public var color: Color { value }
    public var value: Color {
        switch self {
        case .primary: .accentColor
        case .secondary: .subtleFill
        case .text: .primary
        case .textSecondary: .secondary
        case .disabled: .disabled
        case .error: .negative
        case .info: .info
        case .success: .positive
        case .warning: .warning
        case .white: .white
        case .background: .init(white: 0.95)
        case .color(let color): color
        case .hex(let hex): Color(hex: hex)
        }
    }
}
public enum CashlyShape: Shape {
    case circle, capsule
    case rounded(radius: CGFloat)
    public func path(in rect: CGRect) -> Path {
        switch self {
        case .circle: Circle().path(in: rect)
        case .capsule: Capsule().path(in: rect)
        case .rounded(let radius): RoundedRectangle(cornerRadius: radius).path(in: rect)
        }
    }
}
