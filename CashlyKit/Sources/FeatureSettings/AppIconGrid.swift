import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct AppIconGrid: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.shop) private var shop
    let icons: [AppIcon]

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: .spaceS), count: 4),
            spacing: .spaceL
        ) {
            ForEach(icons) { icon in
                AppIconChoice(
                    icon: icon, isSelected: icon == settings.appIcon,
                    isLocked: settings.access(to: icon.shopItem, in: shop).lockedItem != nil
                ) {
                    Task { await settings.choose(icon, in: shop) }
                }
            }
        }
        .padding(.vertical, .spaceS)
        .sensoryFeedback(.selection, trigger: settings.appIcon)
    }
}

private struct AppIconChoice: View {
    @Environment(\.appTint) private var appTint
    let icon: AppIcon
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: .spaceS) {
                AppIconImage(icon: icon, size: .badgeXL)
                    .shadow(color: .black.opacity(.opacityFill), radius: 4, y: 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: .appIconRing, style: .continuous)
                            .stroke(appTint, lineWidth: 3)
                            .padding(-.spaceXS)
                            .opacity(isSelected ? 1 : 0)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if isLocked { LockBadge() }
                    }
                Text(icon.title)
                    .font(.caption.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? appTint : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(icon.title)
        .accessibilityValue(isLocked ? Text("Locked") : Text(verbatim: ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension CGFloat {
    fileprivate static let appIconRing = CGFloat.badgeXL * 0.2237 + .spaceXS
}
