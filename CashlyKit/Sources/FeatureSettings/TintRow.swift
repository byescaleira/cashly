import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TintRow: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        DisclosureLink {
            TintScreen()
        } label: {
            LabeledContent("Cor de destaque") {
                HStack(spacing: .spaceS) {
                    Text(RetroColor.name(for: settings.tint))
                    Circle().fill(Color(hex: settings.tint)).frame(width: 14, height: 14)
                }
            }
        }
    }
}

private struct TintScreen: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            ColorSection(
                hex: $settings.tint,
                footer: "A cor de destaque aparece em botões, abas, seleções e gráficos.")
        }
        .formStyle(.grouped)
        .navigationTitle("Cor de destaque")
    }
}
