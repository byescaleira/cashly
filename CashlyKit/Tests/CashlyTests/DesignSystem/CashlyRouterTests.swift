//
//  CashlyRouterTests.swift
//  CashlyKit
//

import SwiftUI
import Testing
import CashlyDesignSystem

@MainActor
@Suite("CashlyRouter", .tags(.unit, .ui, .local))
struct CashlyRouterTests {
    @Test("init has empty path, no present, no full")
    func initialState() {
        let router = CashlyRouter<TestRoute>()
        #expect(router.navigationPath.isEmpty)
        #expect(router.presentRoute == nil)
        #expect(router.fullRoute == nil)
        #expect(router.isPresenting == false)
    }

    @Test("route(to:) push grows the navigation path")
    func routePush() {
        let router = CashlyRouter<TestRoute>()
        router.route(to: .pushable)
        #expect(router.navigationPath.count == 1)
        #expect(router.presentRoute == nil)
        #expect(router.fullRoute == nil)
    }

    @Test("route(to:) present sets presentRoute")
    func routePresent() {
        let router = CashlyRouter<TestRoute>()
        router.route(to: .presentable)
        #expect(router.presentRoute == .presentable)
        #expect(router.isPresenting == true)
    }

    @Test("route(to:) full sets fullRoute")
    func routeFull() {
        let router = CashlyRouter<TestRoute>()
        router.route(to: .fullable)
        #expect(router.fullRoute == .fullable)
        #expect(router.isPresenting == true)
    }

    @Test("root() clears the navigation path")
    func rootClears() {
        let router = CashlyRouter<TestRoute>()
        router.route(to: .pushable)
        router.route(to: .pushable)
        #expect(router.navigationPath.count == 2)
        router.root()
        #expect(router.navigationPath.isEmpty)
    }

    @Test("dismiss pops path first")
    func dismissPopsPath() {
        let router = CashlyRouter<TestRoute>()
        router.route(to: .pushable)
        router.dismiss()
        #expect(router.navigationPath.isEmpty)
    }

    @Test("dismiss clears present when path empty")
    func dismissClearsPresent() {
        let router = CashlyRouter<TestRoute>()
        router.route(to: .presentable)
        router.dismiss()
        #expect(router.presentRoute == nil)
    }

    @Test("dismiss clears full when path + present empty")
    func dismissClearsFull() {
        let router = CashlyRouter<TestRoute>()
        router.route(to: .fullable)
        router.dismiss()
        #expect(router.fullRoute == nil)
    }
}

// MARK: - Test route

enum TestRoute: String, CashlyRoutable {
    case pushable
    case presentable
    case fullable

    var navigationStyle: CashlyNavigationStyle {
        switch self {
        case .pushable: return .push
        case .presentable: return .present
        case .fullable: return .full
        }
    }

    func makeView(content: @escaping (TestRoute) -> any View) -> some View {
        EmptyView()
    }
}
