import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

struct ShopSection: View {
    @Environment(StoreModel.self) private var store
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        Section {
            ForEach(ShopCatalog.plans) { ShopRow(item: $0) }
            if let featured = ShopItem.featured(on: .now), !store.owns(featured) {
                ShopRow(item: featured, badge: String(appLocalized: "This month"))
            }
            Button("See the Shop", systemImage: "bag") { open(.shop, in: section) }
                .font(.buttonLabel)
        } header: {
            Text("Shop").sectionTitle()
        } footer: {
            Text("Items are yours for good, with or without Cashly Pro.")
        }
    }
}

struct ShopRow: View {
    @Environment(StoreModel.self) private var store
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(\.pro) private var pro
    let item: ShopItem
    var badge: String?

    var body: some View {
        Button {
            if item.kind == .subscription { pro.present() } else { navigation.shopItem = item }
        } label: {
            HStack(spacing: .spaceM) {
                ShopThumbnail(item: item)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(item.title).font(.rowTitle)
                    Text(store.caption(for: item)).font(.footnote).foregroundStyle(.secondary)
                    if let badge {
                        Chip(badge, color: item.color).fixedSize().padding(.top, .space2XS)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if store.owns(item) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.positive)
                } else if let price = store.price(for: item) {
                    Text(price).font(.callout.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
            .contentShape(.rect)
        }
        .tint(Color.primary)
        .accessibilityElement(children: .combine)
    }
}

extension StoreModel {
    func caption(for item: ShopItem) -> String {
        switch item.kind {
        case .subscription: String(appLocalized: "7 days free, then billed automatically")
        case .nonConsumable:
            owns(item) ? String(appLocalized: "Purchased") : item.detail
        case .consumable: item.detail
        }
    }
}
