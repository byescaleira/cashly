import CashlyDomain
import FeatureCore
import FeatureJourney
import FeatureStore
import SwiftUI

struct InspectorStore: ViewModifier {
    @Environment(StoreModel.self) private var store
    @Environment(\.pro) private var pro
    @State private var item: ShopItem?
    @State private var isShowingPaywall = false

    func body(content: Content) -> some View {
        content
            .sheet(item: $item) { ShopItemScreen(item: $0) }
            .sheet(isPresented: $isShowingPaywall) { PaywallScreen() }
            .environment(
                \.shop,
                ShopAccess(
                    owned: store.owned, isPro: pro.isPro, price: { store.price(for: $0) },
                    open: { item = $0 }, presentPro: { isShowingPaywall = true })
            )
            .environment(
                \.pro,
                ProAccess(
                    entitlement: pro.entitlement, isEnforced: pro.isEnforced,
                    isOnHold: pro.isOnHold
                ) {
                    if pro.isOnHold { pro.present() } else { isShowingPaywall = true }
                })
    }
}
