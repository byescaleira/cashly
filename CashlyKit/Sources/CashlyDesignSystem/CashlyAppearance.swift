//
//  CashlyAppearance.swift
//  CashlyKit
//
//  User-facing color-scheme override. Persists in @AppStorage under
//  `cashly.appearance` so the choice survives launches. Default
//  is `.system` — follow the OS preference.
//

import SwiftUI

public enum CashlyAppearance: String, Sendable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    /// Maps to SwiftUI's `colorScheme` environment value. `.system`
    /// returns nil so the OS preference flows through unchanged.
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
