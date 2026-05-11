//
//  CashlyRoutable.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned routing protocol stack. Replaces RyzeRoutable +
//  RyzeNavigationStyle without changing call-site semantics.
//

import SwiftUI

public enum CashlyNavigationStyle: Sendable {
    case push
    case present
    case full
}

public protocol CashlyRoutable: Hashable, Identifiable {
    associatedtype Content: View
    var navigationStyle: CashlyNavigationStyle { get }
    func makeView(content: @escaping (Self) -> any View) -> Content
}

public extension CashlyRoutable {
    var id: Self { self }
}

// Note: conforming types provide their own `hash(into:)`. The previous
// default that combined `id` recursed infinitely once `id == Self`, so
// we no longer offer a default. RawRepresentable enums get Hashable
// synthesis for free; payload-carrying enums must implement it
// explicitly (see MainRoute's discriminator-based hash).
