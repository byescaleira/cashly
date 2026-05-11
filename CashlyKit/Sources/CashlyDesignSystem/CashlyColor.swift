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

public enum CashlyColor: Sendable {
    case primary
    case text
    case textSecondary
    case disabled
    case info
    case success
    case warning
    case error
    case white
    case clear
    case gray
    case secondary
    case yellow
    case background
    case color(Color?)
    case hex(String?)

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
