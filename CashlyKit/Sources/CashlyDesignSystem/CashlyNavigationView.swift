//
//  CashlyNavigationView.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned navigation container. Replaces
//  RyzeNavigationView, keeping push/present/full surfaces.
//

import SwiftUI

public struct CashlyNavigationView<Content: View, Route: CashlyRoutable>: View {
    @Namespace private var transitionNamespace

    @Binding private var router: CashlyRouter<Route>
    private let destination: (Route) -> any View
    private let content: () -> Content

    public init(
        router: Binding<CashlyRouter<Route>>,
        destination: @escaping (Route) -> any View,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._router = router
        self.destination = destination
        self.content = content
    }

    public var body: some View {
        NavigationStack(path: $router.navigationPath) {
            content()
                .navigationDestination(for: Route.self) { route in
                    let view = router.makeView(for: route, content: destination)
                    #if os(iOS)
                    view.navigationTransition(.zoom(sourceID: "zoom", in: transitionNamespace))
                    #else
                    view
                    #endif
                }
        }
        .sheet(item: $router.presentRoute) { route in
            router.makeView(for: route, content: destination)
        }
        #if os(iOS)
        .fullScreenCover(item: $router.fullRoute) { route in
            router.makeView(for: route, content: destination)
        }
        #endif
    }
}
