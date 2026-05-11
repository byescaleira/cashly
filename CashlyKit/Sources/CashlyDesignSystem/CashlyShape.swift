//
//  CashlyShape.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned shape token. Sendable enum used by .cashly(clip:)
//  and .cashly(glass:in:) modifiers.
//

import SwiftUI

/// Shape token used by ``cashly(clip:)`` and ``cashly(glass:in:)``.
/// Sendable enum that resolves to one of the SwiftUI shape primitives.
public enum CashlyShape: Shape, Sendable {
    /// `Capsule` primitive.
    case capsule
    /// `Circle` primitive.
    case circle
    /// `RoundedRectangle` with the given corner radius.
    case rounded(radius: CGFloat)

    public func path(in rect: CGRect) -> Path {
        switch self {
        case .capsule: return Capsule().path(in: rect)
        case .circle: return Circle().path(in: rect)
        case let .rounded(radius): return RoundedRectangle(cornerRadius: radius).path(in: rect)
        }
    }
}
