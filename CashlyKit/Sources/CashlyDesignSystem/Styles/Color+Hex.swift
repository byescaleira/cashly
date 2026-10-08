import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

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
