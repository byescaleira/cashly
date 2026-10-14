import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

public struct ShopItemScreen: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 560
    @State private var barHeight: CGFloat = 120
    let item: ShopItem

    public init(item: ShopItem) {
        self.item = item
    }

    public var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: .spaceXL) {
                    ShopItemTopBar()
                    ShopItemHero(item: item)
                    ShopBenefitList(benefits: item.benefits)
                    ShopPriceCard(item: item)
                }
                .padding(.horizontal, .spaceInset)
                .padding(.bottom, .spaceXL)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    contentHeight = $0
                }
            }
            .readableWidth()
            ShopItemBar(item: item)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    barHeight = $0
                }
        }
        .fontDesign(.rounded)
        .presentationDetents([.height(contentHeight + barHeight)])
        .presentationDragIndicator(.hidden)
        #if !os(visionOS)
            .presentationBackground(.sheetBackground)
        #endif
        .interactiveDismissDisabled(store.isBuying)
        .errorAlert($store.error)
        #if os(macOS)
            .frame(minWidth: 520, minHeight: 640)
        #endif
    }
}

private struct ShopItemTopBar: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Spacer()
            Button("Close", systemImage: "xmark") { dismiss() }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.circle)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(store.isBuying)
        }
        .frame(height: .badgeL)
        .padding(.top, .spaceS)
    }
}

private struct ShopItemHero: View {
    @Environment(StoreModel.self) private var store
    let item: ShopItem

    var body: some View {
        VStack(spacing: .spaceM) {
            ShopHeroPreview(item: item)
            Text(verbatim: item.title).font(.titleLarge)
            Text(verbatim: item.outcome).font(.body).foregroundStyle(.secondary)
            if store.owns(item) {
                Chip("Owned", color: .retroOlive, shape: .capsule)
            } else {
                Chip(item.group.title, color: item.color, shape: .capsule)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

private struct ShopBenefitList: View {
    let benefits: [ShopBenefit]

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceL) {
            ForEach(benefits) { benefit in
                HStack(spacing: .spaceM) {
                    SymbolBadge(benefit.symbol, color: benefit.color, size: .badgeM, style: .filled)
                    Text(verbatim: benefit.title).font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spaceL)
        .background(.sheetCard, in: .rect(cornerRadius: .radiusL))
    }
}

private struct ShopPriceCard: View {
    @Environment(StoreModel.self) private var store
    let item: ShopItem

    var body: some View {
        HStack(spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .space2XS) {
                Text(verbatim: item.quantity ?? String(appLocalized: "One-time purchase"))
                    .font(.rowTitle)
                Text(
                    item.kind == .consumable
                        ? "Credited to this profile, used up as you go."
                        : "Yours for good, on all your devices."
                )
                .font(.rowDetail)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: store.price(for: item) ?? "—")
                .font(.amountRow)
                .foregroundStyle(item.color)
        }
        .padding(.spaceL)
        .background(item.color.opacity(.opacityFill), in: .rect(cornerRadius: .radiusL))
        .accessibilityElement(children: .combine)
    }
}

private struct ShopItemBar: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingNothingToRestore = false
    let item: ShopItem

    var body: some View {
        VStack(spacing: .spaceS) {
            Button(action: perform) {
                ZStack {
                    label.opacity(store.isBuying ? 0 : 1)
                    if store.isBuying { ProgressView() }
                }
            }
            .primaryButton()
            .disabled(store.owns(item) || store.isBuying)
            if store.isPending(item) {
                Text("Waiting for approval from your family organizer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ShopItemLinks(restore: restore)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, .spaceInset)
        .padding(.top, .spaceS)
        .padding(.bottom, .spaceM)
        .alert("Restore Purchases", isPresented: $isShowingNothingToRestore) {
        } message: {
            Text("No purchases to restore on this Apple Account.")
        }
    }

    @ViewBuilder private var label: some View {
        if store.owns(item) {
            Label("Owned", systemImage: "checkmark")
        } else if let price = store.price(for: item) {
            Text("Buy for \(price)")
        } else {
            Text("Restore")
        }
    }

    private func perform() {
        Task {
            if store.price(for: item) == nil {
                await restore()
            } else if await store.buy(item) {
                dismiss()
            }
        }
    }

    private func restore() async {
        if await store.restoreItem(item) {
            dismiss()
        } else if store.error == nil {
            isShowingNothingToRestore = true
        }
    }
}

private struct ShopItemLinks: View {
    @Environment(StoreModel.self) private var store
    let restore: () async -> Void

    var body: some View {
        HStack(spacing: .spaceS) {
            Button("Restore") { Task { await restore() } }
            if let url = StorePolicy.terms {
                Text(verbatim: "·")
                Link("Terms", destination: url)
            }
            if let url = StorePolicy.privacy {
                Text(verbatim: "·")
                Link("Privacy", destination: url)
            }
        }
        .font(.caption)
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .disabled(store.isBuying)
    }
}
