import Foundation

public enum WebPalette {
    public static let fallback = "orange"

    static let colors: [(name: String, rgb: UInt32)] = [
        ("mustard", 0xB8841C), ("orange", 0xC2602A), ("rust", 0xA63D2C), ("olive", 0x5F7A2E),
        ("teal", 0x2A7069), ("denim", 0x3D5F86), ("plum", 0x74415F), ("brown", 0x7E5536),
    ]

    public static func name(for hex: String?) -> String {
        guard let hex, let rgb = rgb(hex) else { return fallback }
        return colors.min { distance($0.rgb, rgb) < distance($1.rgb, rgb) }?.name ?? fallback
    }

    static func rgb(_ hex: String) -> UInt32? {
        let digits = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard digits.count >= 6 else { return nil }
        return UInt32(digits.prefix(6), radix: 16)
    }

    static func distance(_ lhs: UInt32, _ rhs: UInt32) -> Int {
        [16, 8, 0].reduce(0) { total, shift in
            let difference = Int((lhs >> shift) & 255) - Int((rhs >> shift) & 255)
            return total + difference * difference
        }
    }
}
