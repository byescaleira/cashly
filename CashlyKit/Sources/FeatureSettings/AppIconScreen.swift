import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct AppIconScreen: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.shop) private var shop

    var body: some View {
        let collections = settings.iconCollections(on: settings.today)
        SettingsPage("App Icon") {
            CurrentIconSection()
            ForEach(collections.prefix(1), id: \.self) { IconCollectionSection(collection: $0) }
            if settings.offersAllIcons(in: shop) { AllIconsSection() }
            ForEach(collections.dropFirst(), id: \.self) { IconCollectionSection(collection: $0) }
            ShopLinkSection()
        }
        .task { await settings.followDayChanges() }
    }
}

private struct CurrentIconSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                AppIconImage(icon: settings.appIcon, size: .badgeXL * 1.5)
                    .shadow(color: .black.opacity(.opacityTint), radius: 10, y: 4)
                    .id(settings.appIcon)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                VStack(spacing: .space2XS) {
                    Text(settings.appIcon.title).font(.titleMedium)
                    Text(settings.appIcon.collection.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceM)
            .animation(reduceMotion ? nil : .smooth, value: settings.appIcon)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct IconCollectionSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.shop) private var shop
    let collection: AppIcon.Collection

    var body: some View {
        let isFeatured = settings.isFeatured(collection, on: settings.today)
        Section {
            AppIconGrid(icons: collection.icons)
        } header: {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: .space2XS) {
                    if isFeatured { FeaturedLabel() }
                    Text(collection.title).sectionTitle()
                }
                Spacer()
                PackAccessButton(access: settings.access(to: collection, in: shop))
            }
            .textCase(nil)
        } footer: {
            if isFeatured {
                Text("Featured this month and available all year.")
            } else if collection.isProOnly {
                Text("Exclusive to Cashly Pro.")
            }
        }
    }
}

private struct FeaturedLabel: View {
    @Environment(\.appTint) private var appTint

    var body: some View {
        Label("Icons of the Month", systemImage: "sparkles")
            .font(.chipLabel)
            .textCase(.uppercase)
            .foregroundStyle(appTint)
    }
}

private struct AllIconsSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.shop) private var shop

    var body: some View {
        Section {
            Button {
                shop.open(.iconsAll)
            } label: {
                HStack(spacing: .spaceM) {
                    AllIconsThumbnail()
                    VStack(alignment: .leading, spacing: .space2XS) {
                        Text("All Icons").font(.rowTitle)
                        Text("Every icon pack, including the ones still to come.")
                            .font(.rowDetail)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: .spaceS)
                    PackAccessChip(access: .locked(.iconsAll))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct AllIconsThumbnail: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        let icons = settings.allIconsPreview
        Grid(horizontalSpacing: .spaceHairline, verticalSpacing: .spaceHairline) {
            GridRow {
                ForEach(icons.prefix(2)) {
                    AppIconImage(icon: $0, size: (.badgeL - .spaceHairline) / 2)
                }
            }
            GridRow {
                ForEach(icons.dropFirst(2)) {
                    AppIconImage(icon: $0, size: (.badgeL - .spaceHairline) / 2)
                }
            }
        }
        .frame(width: .badgeL, height: .badgeL)
    }
}
