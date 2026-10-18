import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct HomeToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .leading) { UserMenu() }
        ToolbarItem { ConverterButton() }
        FixedToolbarSpacer()
        ToolbarItem { FilterMenu() }
        FixedToolbarSpacer()
        ToolbarItem(placement: .primaryAction) { ShopButton() }
    }
}

private struct ConverterButton: View {
    @Environment(\.open) private var open

    var body: some View {
        Button("Converter", systemImage: "arrow.left.arrow.right") {
            open(.converter, in: .home)
        }
        .tint(Color.primary)
    }
}

private struct ShopButton: View {
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        Button("Shop", systemImage: "bag") { open(.shop, in: section) }
            .tint(Color.primary)
    }
}
