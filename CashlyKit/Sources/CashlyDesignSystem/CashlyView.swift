//
//  CashlyView.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned base protocol for screen and component views.
//  Adds a canAppear hook for navigation gating and a mocked() factory for
//  preview/test stubs.
//

import SwiftUI

@MainActor
public protocol CashlyView: View {
    associatedtype MockView: View
    static func mocked() -> MockView
    var canAppear: Bool { get }
}

public extension CashlyView {
    var canAppear: Bool { true }
    @MainActor
    static func mocked() -> some View { EmptyView() }
}
