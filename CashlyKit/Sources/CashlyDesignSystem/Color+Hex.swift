//
//  Color+Hex.swift
//  CashlyKit
//
//  Wave 5b: hex-string initializer for SwiftUI.Color. Accepts
//  "#RRGGBB" or "RRGGBB" or "#RRGGBBAA". Falls back to .clear when
//  string is nil or unparseable.
//

import SwiftUI

public extension Color {
    init(hex: String?) {
        guard let hex else {
            self = .clear
            return
        }
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }
        guard trimmed.count == 6 || trimmed.count == 8 else {
            self = .clear
            return
        }
        var rgba: UInt64 = 0
        guard Scanner(string: trimmed).scanHexInt64(&rgba) else {
            self = .clear
            return
        }
        let hasAlpha = trimmed.count == 8
        let r = Double((rgba >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = Double((rgba >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = Double((rgba >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? Double(rgba & 0xFF) / 255 : 1
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

public extension Color {
    /// Hex string representation (RRGGBB) of the color via cgColor.
    /// Returns empty string when components can't be resolved (e.g. dynamic system colors).
    var hex: String {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "#%02X%02X%02X",
            Int((r * 255).rounded()),
            Int((g * 255).rounded()),
            Int((b * 255).rounded())
        )
        #else
        return ""
        #endif
    }
}
