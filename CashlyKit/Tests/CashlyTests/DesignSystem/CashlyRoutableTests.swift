//
//  CashlyRoutableTests.swift
//  CashlyKit
//
//  Verify the default `id` / `hash(into:)` implementations on the
//  CashlyRoutable protocol.
//

import SwiftUI
import Testing
import CashlyDesignSystem

@Suite("CashlyRoutable defaults", .tags(.unit, .ui, .local))
struct CashlyRoutableTests {

    @Test("default id is Self (the route itself)")
    func idIsSelf() {
        let r = SimpleRoute.first
        #expect(r.id == r)
    }

    @Test("equal routes hash equally")
    func hashEqualForEqualRoutes() {
        let a = SimpleRoute.first
        let b = SimpleRoute.first
        var h1 = Hasher()
        var h2 = Hasher()
        a.hash(into: &h1)
        b.hash(into: &h2)
        #expect(h1.finalize() == h2.finalize())
    }

    @Test("different routes hash differently")
    func hashDiffersAcrossRoutes() {
        let a = SimpleRoute.first
        let b = SimpleRoute.second
        var h1 = Hasher()
        var h2 = Hasher()
        a.hash(into: &h1)
        b.hash(into: &h2)
        #expect(h1.finalize() != h2.finalize())
    }

    @Test("CashlyNavigationStyle.push exists distinct from present/full")
    func navigationStyleValues() {
        let styles: [CashlyNavigationStyle] = [.push, .present, .full]
        // No Equatable conformance guaranteed, switch instead.
        var pushSeen = false
        var presentSeen = false
        var fullSeen = false
        for s in styles {
            switch s {
            case .push: pushSeen = true
            case .present: presentSeen = true
            case .full: fullSeen = true
            }
        }
        #expect(pushSeen && presentSeen && fullSeen)
    }
}

// MARK: - Fixture

enum SimpleRoute: String, CashlyRoutable {
    case first
    case second

    var navigationStyle: CashlyNavigationStyle { .push }

    func makeView(content: @escaping (SimpleRoute) -> any View) -> some View {
        EmptyView()
    }
}
