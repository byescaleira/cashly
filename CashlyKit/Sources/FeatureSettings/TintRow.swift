import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TintRow: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        DisclosureLink {
            TintScreen()
        } label: {
            LabeledContent("Accent Color") {
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
    @Environment(\.shop) private var shop

    var body: some View {
        @Bindable var settings = settings
        Form {
            ColorSection(
                hex: $settings.tint,
                footer: String(
                    appLocalized:
                        "The accent color appears on buttons, tabs, selections and charts."))
            PremiumColorSection(item: .accentMetallic, title: "Metallic", hex: $settings.tint)
            PremiumColorSection(item: .accentNeon, title: "Neon", hex: $settings.tint)
        }
        .formStyle(.grouped)
        .navigationTitle("Accent Color")
    }
}

private struct PremiumColorSection: View {
    @Environment(\.shop) private var shop
    let item: ShopItem
    let title: LocalizedStringKey
    @Binding var hex: String

    var body: some View {
        let isLocked = !shop.owns(item)
        Section {
            PremiumColorPicker(
                colors: PremiumColor.colors(of: item), hex: $hex, isLocked: isLocked
            ) {
                shop.open(item)
            }
        } header: {
            HStack {
                Text(title).sectionTitle()
                Spacer()
                if isLocked {
                    Image(systemName: "lock.fill").foregroundStyle(.secondary)
                }
            }
        } footer: {
            if isLocked { Text("Available in the Journey shop.") }
        }
    }
}
