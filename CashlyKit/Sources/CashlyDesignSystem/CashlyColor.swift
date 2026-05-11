//
//  CashlyColor.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned color token. Replaces Ryze theme indirection
//  with fixed semantic mappings to SwiftUI.Color.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Semantic color token used across Cashly UI.
///
/// Resolves to a concrete `SwiftUI.Color` via ``resolved``. Use named
/// cases (e.g. `.primary`, `.error`) for tokens that should track app
/// theming, and the escape-hatch cases — ``CashlyColor/color(_:)`` and
/// ``CashlyColor/hex(_:)`` — for one-off colors driven by data (such as
/// per-tag user-picked colors).
///
/// ```swift
/// CashlyText("Total")
///     .cashly(color: .text)
///     .cashly(background: .info)
/// ```
public enum CashlyColor: Sendable {
    /// App accent color (`Color.accentColor`).
    case primary
    /// Primary foreground (`Color.primary`).
    case text
    /// Secondary foreground (`Color.secondary`).
    case textSecondary
    /// 40%-opacity gray, for disabled affordances.
    case disabled
    /// Informational blue.
    case info
    /// Success green.
    case success
    /// Warning orange.
    case warning
    /// Destructive red.
    case error
    case white
    case clear
    case gray
    case secondary
    case yellow
    /// Platform system background (UIKit `systemBackground` / AppKit
    /// `windowBackgroundColor`).
    case background
    /// Arbitrary SwiftUI color escape hatch. Resolves to `.clear` when
    /// the wrapped value is `nil`.
    case color(Color?)
    /// Hex string escape hatch (`#RRGGBB` or `#RRGGBBAA`). Resolves to
    /// `.clear` when nil or malformed.
    case hex(String?)

    /// Resolves the token to a `SwiftUI.Color` usable inside views.
    public var resolved: Color {
        switch self {
        case .primary: return .accentColor
        case .text: return .primary
        case .textSecondary: return .secondary
        case .disabled: return .gray.opacity(0.4)
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .white: return .white
        case .clear: return .clear
        case .gray: return .gray
        case .secondary: return .secondary
        case .yellow: return .yellow
        #if canImport(UIKit)
        case .background: return Color(UIColor.systemBackground)
        #else
        case .background: return Color(NSColor.windowBackgroundColor)
        #endif
        case let .color(c): return c ?? .clear
        case let .hex(hexValue): return Color(hex: hexValue)
        }
    }
}
