//
//  CashlySpacing.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned spacing token. Fixed CGFloat scale (no theme
//  protocol indirection). Use via CashlyHStack/VStack/ZStack and the
//  `.cashlyPadding(...)` modifier.
//

import SwiftUI

/// Spacing token used by stacks and the `.cashlyPadding(...)`
/// modifier. Fixed CGFloat scale — no theme indirection.
///
/// Use named cases (`extraSmall` ... `section`) for visual rhythm,
/// `negative(_:)` for overlap effects, and `custom(_:)` as an escape
/// hatch.
public indirect enum CashlySpacing: Sendable, Equatable {
    case zero
    case extraSmall
    case small
    case medium
    case large
    case extraLarge
    case ultraLarge
    case section
    case negative(CashlySpacing)
    case custom(CGFloat)

    public var rawValue: CGFloat {
        switch self {
        case .zero: return 0
        case .extraSmall: return 4
        case .small: return 8
        case .medium: return 16
        case .large: return 24
        case .extraLarge: return 32
        case .ultraLarge: return 48
        case .section: return 64
        case let .negative(spacing): return -spacing.rawValue
        case let .custom(value): return value
        }
    }
}
