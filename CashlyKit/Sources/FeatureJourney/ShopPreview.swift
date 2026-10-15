import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ShopCardPreview: View {
    let item: ShopItem

    var body: some View {
        Group {
            switch item.group {
            case .icons: IconPackGrid(icons: item.previewIcons, columns: item == .iconsAll ? 3 : 2)
            case .avatars:
                AvatarPackGrid(
                    illustrations: Array(
                        item.previewIllustrations.prefix(item == .avatarsAll ? 6 : 4)),
                    columns: item == .avatarsAll ? 3 : 2)
            case .personalization: SwatchGrid(colors: PremiumColor.colors(of: item), columns: 2)
            case .helps, .plans: CashlyAnimationView(item.animation)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: .badgeXL * 2)
    }
}

struct ShopHeroPreview: View {
    let item: ShopItem

    var body: some View {
        switch item.group {
        case .icons where item == .iconsAll:
            IconPackGrid(icons: AppIcon.icons(of: item), columns: 9)
                .frame(height: .badgeXL * 3)
        case .icons: IconPackRow(icons: AppIcon.icons(of: item))
        case .avatars:
            AvatarPackGrid(
                illustrations: item.heroIllustrations, columns: item == .avatarsAll ? 3 : 5
            )
            .frame(height: .badgeXL * 2 + .spaceXS)
        case .personalization: SwatchRow(colors: PremiumColor.colors(of: item))
        case .helps, .plans: CashlyAnimationView(item.animation).frame(maxWidth: 260)
        }
    }
}

extension ShopItem {
    fileprivate var heroIllustrations: [ProfileIllustration] {
        guard self == .avatarsAll else {
            return Array(ProfileIllustration.illustrations(of: self).prefix(10))
        }
        return previewIllustrations
    }
}

private struct AvatarPackGrid: View {
    let illustrations: [ProfileIllustration]
    let columns: Int

    var body: some View {
        GeometryReader { proxy in
            let rows = (illustrations.count + columns - 1) / columns
            let side = min(
                (proxy.size.width - .spaceXS * CGFloat(columns - 1)) / CGFloat(columns),
                (proxy.size.height - .spaceXS * CGFloat(rows - 1)) / CGFloat(rows))
            Grid(horizontalSpacing: .spaceXS, verticalSpacing: .spaceXS) {
                ForEach(0..<rows, id: \.self) { row in
                    GridRow {
                        ForEach(
                            illustrations[
                                row * columns..<min((row + 1) * columns, illustrations.count)]
                        ) {
                            ProfileAvatar(photo: .illustration($0.id), initials: "", size: side)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}

private struct IconPackRow: View {
    let icons: [AppIcon]

    var body: some View {
        HStack(alignment: .top, spacing: .spaceM) {
            ForEach(icons) { icon in
                VStack(spacing: .spaceS) {
                    AppIconImage(icon: icon, size: .badgeXL + .spaceS)
                        .shadow(color: .black.opacity(.opacityFill), radius: 4, y: 2)
                    Text(icon.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SwatchRow: View {
    let colors: [PremiumColor]

    var body: some View {
        HStack(alignment: .top, spacing: .spaceM) {
            ForEach(colors) { color in
                VStack(spacing: .spaceS) {
                    Circle()
                        .fill(color.color.gradient)
                        .frame(width: .badgeXL + .spaceS, height: .badgeXL + .spaceS)
                        .shadow(color: .black.opacity(.opacityFill), radius: 4, y: 2)
                    Text(color.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
