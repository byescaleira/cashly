import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct AppIconScreen: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        let featured = AppIcon.featured(on: .now)
        Form {
            if let featured {
                FeaturedIconsSection(collection: featured)
            }
            ForEach(AppIcon.Collection.allCases.filter { $0 != featured }, id: \.self) {
                collection in
                Section(collection.title) {
                    IconGrid(icons: collection.icons, size: 62)
                }
            }
        }
        .formStyle(.grouped)
        .readableWidth()
        .navigationTitle("Icon")
        .alert("Icon", isPresented: $settings.isShowingIconError) {
        } message: {
            Text(settings.iconError ?? "")
        }
    }
}

private struct FeaturedIconsSection: View {
    let collection: AppIcon.Collection

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: .spaceL) {
                VStack(alignment: .leading, spacing: .space2XS) {
                    Label("Icons of the Month", systemImage: "sparkles")
                        .font(.chipLabel)
                        .textCase(.uppercase)
                        .foregroundStyle(.white.opacity(.opacityStrong))
                    Text(collection.title)
                        .font(.titleMedium)
                        .foregroundStyle(.white)
                }
                IconGrid(icons: collection.icons, size: 66)
                    .foregroundStyle(.white)
            }
            .padding(.vertical, .spaceM)
            .listRowBackground(
                LinearGradient(
                    colors: [Color(hex: "3A2340"), Color(hex: "7A1418"), Color(hex: "C8642B")],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
        } footer: {
            Text("Featured this month and available all year.")
        }
    }
}

private struct IconGrid: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.shop) private var shop
    let icons: [AppIcon]
    let size: CGFloat

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: .spaceS), count: 4),
            spacing: .spaceL
        ) {
            ForEach(icons) { icon in
                let lock = icon.shopItem.flatMap { shop.owns($0) ? nil : $0 }
                IconChoice(
                    icon: icon, size: size, isSelected: icon == settings.appIcon,
                    isLocked: lock != nil
                ) {
                    if let lock {
                        shop.open(lock)
                    } else {
                        Task { await settings.setAppIcon(icon) }
                    }
                }
            }
        }
        .padding(.vertical, .spaceS)
        .sensoryFeedback(.selection, trigger: settings.appIcon)
    }
}

private struct IconChoice: View {
    @Environment(\.appTint) private var appTint
    let icon: AppIcon
    let size: CGFloat
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: .spaceS) {
                AppIconImage(icon: icon, size: size)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.2237 + 5, style: .continuous)
                            .stroke(appTint, lineWidth: 3)
                            .padding(-.space2XS)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.spaceXS)
                                .background(.black.opacity(.opacityStrong), in: .circle)
                                .offset(x: .spaceXS, y: .spaceXS)
                        }
                    }
                    .shadow(color: .black.opacity(.opacityFill), radius: 4, y: 2)
                Text(icon.title)
                    .font(.caption.weight(isSelected ? .bold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon.title)
        .accessibilityValue(isLocked ? Text("Locked") : Text(verbatim: ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
