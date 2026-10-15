import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct ShopThumbnail: View {
    let item: ShopItem

    public init(item: ShopItem) {
        self.item = item
    }

    public var body: some View {
        switch item.group {
        case .icons:
            IconPackGrid(icons: Array(item.previewIcons.prefix(4)), columns: 2)
                .frame(width: .badgeL, height: .badgeL)
        case .avatars:
            ProfileAvatar(
                photo: item.previewIllustrations.first.map { .illustration($0.id) } ?? .default,
                initials: "", size: .badgeL
            )
            .accessibilityHidden(true)
        case .personalization:
            SwatchGrid(colors: PremiumColor.colors(of: item), columns: 2)
                .frame(width: .badgeL, height: .badgeL)
        case .helps, .plans: SymbolBadge(item.symbol, color: item.color, size: .badgeL)
        }
    }
}

extension ShopItem {
    public var previewIcons: [AppIcon] {
        guard self == .iconsAll else { return AppIcon.icons(of: self) }
        return ShopCatalog.items(in: .icons).filter { $0 != .iconsAll }
            .compactMap { AppIcon.icons(of: $0).first }
    }

    public var previewIllustrations: [ProfileIllustration] {
        guard self == .avatarsAll else {
            return Array(ProfileIllustration.illustrations(of: self).prefix(4))
        }
        return ProfileIllustration.Section.sections(of: self).compactMap(\.illustrations.first)
    }
}

public struct IconPackGrid: View {
    let icons: [AppIcon]
    let columns: Int

    public init(icons: [AppIcon], columns: Int) {
        self.icons = icons
        self.columns = columns
    }

    public var body: some View {
        GeometryReader { proxy in
            let rows = (icons.count + columns - 1) / columns
            let side = min(
                (proxy.size.width - .spaceXS * CGFloat(columns - 1)) / CGFloat(columns),
                (proxy.size.height - .spaceXS * CGFloat(rows - 1)) / CGFloat(rows))
            Grid(horizontalSpacing: .spaceXS, verticalSpacing: .spaceXS) {
                ForEach(0..<rows, id: \.self) { row in
                    GridRow {
                        ForEach(icons[row * columns..<min((row + 1) * columns, icons.count)]) {
                            AppIconImage(icon: $0, size: side)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}

public struct SwatchGrid: View {
    let colors: [PremiumColor]
    let columns: Int

    public init(colors: [PremiumColor], columns: Int) {
        self.colors = colors
        self.columns = columns
    }

    public var body: some View {
        GeometryReader { proxy in
            let rows = (colors.count + columns - 1) / columns
            let side = min(
                (proxy.size.width - .spaceXS * CGFloat(columns - 1)) / CGFloat(columns),
                (proxy.size.height - .spaceXS * CGFloat(rows - 1)) / CGFloat(rows))
            Grid(horizontalSpacing: .spaceXS, verticalSpacing: .spaceXS) {
                ForEach(0..<rows, id: \.self) { row in
                    GridRow {
                        ForEach(colors[row * columns..<min((row + 1) * columns, colors.count)]) {
                            Circle().fill($0.color.gradient).frame(width: side, height: side)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }
}
