import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct HomeToolbar: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .leading) { UserMenu() }
        ToolbarItem { ConverterButton() }
        FixedToolbarSpacer()
        ToolbarItem { FilterMenu() }
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
