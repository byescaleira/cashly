import SwiftUI

public struct RouteViewBuilder: Sendable {
    private let build: @MainActor @Sendable (Route) -> AnyView

    public init<Content: View>(
        @ViewBuilder _ build: @escaping @MainActor @Sendable (Route) -> Content
    ) {
        self.build = { AnyView(build($0)) }
    }

    @MainActor func view(for route: Route) -> AnyView {
        build(route)
    }
}

public struct RouteView: View {
    @Environment(\.routeView) private var routeView
    @Environment(\.dismiss) private var dismiss
    private let route: Route

    public init(_ route: Route) {
        self.route = route
    }

    public var body: some View {
        routeView.view(for: route)
            .environment(\.close, CloseAction { dismiss() })
    }
}
