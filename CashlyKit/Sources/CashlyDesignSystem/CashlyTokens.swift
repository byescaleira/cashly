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
        case .secondary: .secondary.opacity(0.12)
        case .text: .primary
        case .textSecondary: .secondary
        case .disabled: .gray
        case .error: .red
        case .info: .blue
        case .success: .green
        case .warning: .orange
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
extension Color {
    public init(hex: String?) {
        let text = (hex ?? "").trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard let value = UInt64(text, radix: 16), [6, 8].contains(text.count) else {
            self = .accentColor
            return
        }
        let rgba = text.count == 8 ? value : (value << 8) | 255
        self.init(
            .sRGB, red: Double((rgba >> 24) & 255) / 255,
            green: Double((rgba >> 16) & 255) / 255,
            blue: Double((rgba >> 8) & 255) / 255, opacity: Double(rgba & 255) / 255)
    }
    @MainActor public var hex: String {
        #if canImport(UIKit)
            let color = UIColor(self)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return "808080"
            }
        #elseif canImport(AppKit)
            guard let color = NSColor(self).usingColorSpace(.sRGB) else { return "808080" }
            let red = color.redComponent
            let green = color.greenComponent
            let blue = color.blueComponent
            let alpha = color.alphaComponent
        #else
            let red = 0.5
            let green = 0.5
            let blue = 0.5
            let alpha = 1.0
        #endif
        return String(
            format: "%02X%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255),
            Int(alpha * 255))
    }
}
extension EnvironmentValues {
    @Entry public var isLoading: Bool = false
}
