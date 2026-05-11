//
//  CashlyRoutable.swift
//  CashlyKit
//
//  Cashly-owned routing protocol stack. Routes conform to
//  ``CashlyRoutable``; navigation policies expressed via
//  ``CashlyNavigationStyle`` are interpreted by ``CashlyRouter``.
//

import SwiftUI

/// How a route should be presented when handed to a ``CashlyRouter``.
public enum CashlyNavigationStyle: Sendable {
    /// Push onto the navigation stack.
    case push
    /// Present as a sheet.
    case present
    /// Present as a fullscreen cover (iOS only — collapses to sheet on
    /// other platforms via SwiftUI).
    case full
}

/// A destination that ``CashlyRouter`` can navigate to.
///
/// Conformers must be `Hashable` (so the navigation stack can encode
/// the path) and `Identifiable` — a default `id == Self` is supplied
/// by the protocol. The Hashable conformance must be implemented by
/// the concrete type: `RawRepresentable` enums get synthesis for free,
/// payload-carrying enums use a discriminator-based hash (see
/// `MainRoute` in CashlyPresentation).
public protocol CashlyRoutable: Hashable, Identifiable {
    associatedtype Content: View
    /// How this route prefers to be presented.
    var navigationStyle: CashlyNavigationStyle { get }
    /// Renders the destination view. `content` is provided by the host
    /// router so the conformer can defer to a shared destination
    /// factory.
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
