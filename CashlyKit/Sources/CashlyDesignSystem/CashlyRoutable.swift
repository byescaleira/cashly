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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
