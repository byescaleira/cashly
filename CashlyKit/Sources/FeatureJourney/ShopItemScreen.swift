import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

public struct ShopItemScreen: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isBuying = false
    @State private var isPending = false
    let item: ShopItem

    public init(item: ShopItem) {
        self.item = item
    }

    public var body: some View {
        @Bindable var store = store
        GuideSheet(index: 0, count: 1, isWorking: isBuying, primary: primary, secondary: secondary)
        {
            GuidePage(verbatim: item.title, message: item.detail) {
                CashlyAnimationView(item.group.animation)
            } content: {
                GuideValueList(rows)
                if isPending {
                    Text("Waiting for approval from your family organizer.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .errorAlert($store.error)
    }

    private var rows: [GuideValue] {
        [
            GuideValue(
                String(appLocalized: "Price"), value: store.price(for: item) ?? "—",
                color: item.color),
            GuideValue(
                String(appLocalized: "After buying"),
                value: item.kind == .consumable
                    ? String(appLocalized: "Used up as you go, on this profile")
                    : String(appLocalized: "Yours for good, on all your devices")),
        ]
    }

    private var primary: GuideAction {
        if store.owns(item) { return GuideAction("Done") { dismiss() } }
        let title: LocalizedStringKey =
            if let price = store.price(for: item) { "Buy for \(price)" } else { "Buy" }
        return GuideAction(title, isEnabled: store.hasLoaded) { Task { await buy() } }
    }

    private var secondary: GuideAction? {
        store.owns(item) ? nil : GuideAction("Not Now") { dismiss() }
    }

    private func buy() async {
        isBuying = true
        defer { isBuying = false }
        do {
            switch try await store.purchase(item) {
            case .purchased: dismiss()
            case .pending: isPending = true
            case .cancelled: break
            }
        } catch {
            store.error = error as? CashlyError
        }
    }
}

extension ShopItem.Group {
    var animation: CashlyAnimation {
        switch self {
        case .plans: .pro
        case .icons: .shopIcons
        case .personalization: .shopColors
        case .helps: .shopHelps
        }
    }
}
