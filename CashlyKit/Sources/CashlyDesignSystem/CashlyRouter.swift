//
//  CashlyRouter.swift
//  CashlyKit
//
//  Cashly-owned router. Push/present/full semantics + dismiss/root
//  affordances. @Observable so SwiftUI tracks stack changes.
//

import SwiftUI

/// Stack-aware navigation router for a single route type.
///
/// Tracks three independent surfaces:
/// - a push stack (`navigationPath`),
/// - a single sheet route (`presentRoute`),
/// - a single fullscreen route (`fullRoute`).
///
/// ``CashlyNavigationView`` consumes the router to drive a
/// `NavigationStack` plus `.sheet` and `.fullScreenCover` modifiers.
/// `dismiss()` pops in priority order (path → present → full → host
/// binding), so a single back-button call works regardless of which
/// surface produced the current destination.
@Observable
public final class CashlyRouter<Route: CashlyRoutable>: @unchecked Sendable, Equatable {
    public var navigationPath = NavigationPath()
    public var isPresented: Binding<Route?>
    public var presentRoute: Route?
    public var fullRoute: Route?

    public var isPresenting: Bool {
        presentRoute != nil || fullRoute != nil
    }

    public init(isPresented: Binding<Route?> = .constant(.none)) {
        self.isPresented = isPresented
    }

    public func makeView(for route: Route, content: @escaping (Route) -> any View) -> some View {
        route.makeView(content: content)
    }

    public func route(to destination: Route) {
        switch destination.navigationStyle {
        case .push: navigationPath.append(destination)
        case .present: presentRoute = destination
        case .full: fullRoute = destination
        }
    }

    public func root() {
        navigationPath = .init()
    }

    public func dismiss() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        } else if presentRoute != nil {
            presentRoute = nil
        } else if fullRoute != nil {
            fullRoute = nil
        } else {
            isPresented.wrappedValue = nil
        }
    }

    public static func == (lhs: CashlyRouter<Route>, rhs: CashlyRouter<Route>) -> Bool {
        lhs.presentRoute?.id == rhs.presentRoute?.id &&
        lhs.fullRoute?.id == rhs.fullRoute?.id &&
        lhs.navigationPath.count == rhs.navigationPath.count
    }
}
