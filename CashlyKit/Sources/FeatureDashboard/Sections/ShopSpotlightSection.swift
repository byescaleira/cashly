import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ShopSpotlightSection: View {
    @Environment(DashboardModel.self) private var dashboard
    @Environment(\.shop) private var shop
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if let item = dashboard.shopSpotlight(owned: shop.owned) {
            Section {
                Button {
                    shop.open(item)
                } label: {
                    ShopSpotlightRow(item: item)
                }
                .tint(Color.primary)
                .swipeActions {
                    Button("Not Now", systemImage: "eye.slash") { dashboard.hideShopSpotlight() }
                }
                .contextMenu {
                    Button("Not Now", systemImage: "eye.slash") { dashboard.hideShopSpotlight() }
                }
                Button("See the Shop", systemImage: "bag") { open(.shop, in: section) }
                    .font(.buttonLabel)
            } header: {
                HStack(alignment: .firstTextBaseline) {
                    Text("From the Shop").sectionTitle()
                    Spacer()
                    Button("Not Now", systemImage: "xmark") { dashboard.hideShopSpotlight() }
                        .labelStyle(.iconOnly)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: .rowHeight, minHeight: .rowHeight)
                        .contentShape(.rect)
                }
                .textCase(nil)
            } footer: {
                Text("Items are yours for good, with or without Cashly Pro.")
            }
        }
    }
}

private struct ShopSpotlightRow: View {
    @Environment(\.shop) private var shop
    let item: ShopItem

    var body: some View {
        HStack(spacing: .spaceM) {
            ShopThumbnail(item: item)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(item.title).font(.rowTitle)
                Text(item.detail).font(.footnote).foregroundStyle(.secondary)
                if item.isSeasonal {
                    Chip(String(appLocalized: "This month"), color: item.color)
                        .fixedSize()
                        .padding(.top, .space2XS)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let price = shop.price(for: item) {
                Text(price).font(.callout.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
