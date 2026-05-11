//
//  CashlyShape.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned shape token. Sendable enum used by .cashly(clip:)
//  and .cashly(glass:in:) modifiers.
//

import SwiftUI

public enum CashlyShape: Shape, Sendable {
    case capsule
    case circle
    case rounded(radius: CGFloat)

    public func path(in rect: CGRect) -> Path {
        switch self {
        case .capsule: return Capsule().path(in: rect)
        case .circle: return Circle().path(in: rect)
        case let .rounded(radius): return RoundedRectangle(cornerRadius: radius).path(in: rect)
        }
    }
}
