import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

public struct ShopScreen: View {
    @Environment(StoreModel.self) private var store

    public init() {}

    public var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(spacing: .space2XL) {
                ShopProCard()
                ForEach(ShopItem.Group.allCases.filter { $0 != .plans }, id: \.self) {
                    ShopGroup(group: $0)
                }
                ShopFooter()
            }
            .padding(.horizontal, .spaceInset)
            .padding(.vertical, .spaceL)
        }
        .background(.groupedBackground)
        .readableWidth()
        .fontDesign(.rounded)
        .navigationTitle("Shop")
        .errorAlert($store.error)
    }
}

private struct ShopProCard: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.pro) private var pro

    var body: some View {
        Button(action: pro.present) {
            HStack(spacing: .spaceM) {
                CashlyAnimationView(.pro).frame(width: .badgeXL * 2)
                VStack(alignment: .leading, spacing: .spaceXS) {
                    Text("Cashly Pro").font(.rowTitle)
                    Text(detail).font(.rowDetail).foregroundStyle(.secondary)
                    chip
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.icon(.s, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .multilineTextAlignment(.leading)
            .padding(.spaceL)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(.groupedRow, in: .rect(cornerRadius: .radiusL))
        .accessibilityElement(children: .combine)
    }

    private var detail: String {
        store.entitlement.detail ?? String(appLocalized: "Your whole month, without limits")
    }

    @ViewBuilder private var chip: some View {
        if store.entitlement.isActive {
            Chip(store.entitlement.title, color: .retroOlive)
        } else if let days = store.trialDays {
            Chip("\(days) days free", color: .retroMustard)
        } else {
            Chip("See plans", color: .retroMustard)
        }
    }
}

private struct ShopGroup: View {
    let group: ShopItem.Group

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceM) {
            Text(group.title).sectionTitle()
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 150), spacing: .spaceM)], spacing: .spaceM
            ) {
                ForEach(ShopCatalog.items(in: group)) { ShopCard(item: $0) }
            }
            if group == .helps {
                Text("Helps are used up as you go and belong to this profile.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ShopCard: View {
    @Environment(CashlyNavigation.self) private var navigation
    let item: ShopItem

    var body: some View {
        Button {
            navigation.shopItem = item
        } label: {
            VStack(alignment: .leading, spacing: .spaceM) {
                ShopCardPreview(item: item)
                VStack(alignment: .leading, spacing: .space2XS) {
                    Text(item.title).font(.rowTitle).lineLimit(1)
                    Text(item.outcome)
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                }
                ShopPriceChip(item: item)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spaceL)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(.groupedRow, in: .rect(cornerRadius: .radiusL))
        .accessibilityElement(children: .combine)
    }
}

struct ShopPriceChip: View {
    @Environment(StoreModel.self) private var store
    let item: ShopItem

    var body: some View {
        if store.owns(item) {
            Chip("Owned", color: .retroOlive)
        } else if let price = store.price(for: item) {
            Chip(price, color: item.color)
        }
    }
}

private struct ShopFooter: View {
    @Environment(StoreModel.self) private var store
    @State private var message: LocalizedStringKey?

    var body: some View {
        VStack(spacing: .spaceS) {
            Button("Restore Purchases") { Task { await restore() } }
                .font(.buttonLabel)
                .buttonStyle(.borderless)
                .disabled(store.isBuying)
            Text("Purchases belong to your Apple Account and work on all your devices.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .alert("Restore Purchases", isPresented: isShowingMessage) {
        } message: {
            if let message { Text(message) }
        }
    }

    private var isShowingMessage: Binding<Bool> {
        Binding(get: { message != nil }, set: { if !$0 { message = nil } })
    }

    private func restore() async {
        let restored = await store.restoreItems()
        guard store.error == nil else { return }
        message =
            restored ? "Your purchases are back." : "No purchases to restore on this Apple Account."
    }
}
