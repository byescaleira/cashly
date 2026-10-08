import CashlyDomain
import CashlyPresentation
import CashlyUI
import FeatureCore
import SwiftUI

struct SheetScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CashlyNavigation.self) private var navigation
    let destination: CashlyNavigation.SheetDestination

    var body: some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.sheetPath) {
            RouteScreen(route: destination.route)
                .navigationDestination(for: Route.self) { RouteScreen(route: $0) }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
        .environment(\.navigationSection, destination.section)
        .presentationDetents([.large])
    }
}
