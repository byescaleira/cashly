import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import StoreKit
import SwiftUI

struct ProSection: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.pro) private var pro
    @State private var message: String?

    var body: some View {
        @Bindable var store = store
        Section {
            IconRow(
                verbatim: store.entitlement.title, detail: store.entitlement.detail,
                symbol: "crown", color: .retroMustard)
            if !store.entitlement.isActive {
                Button {
                    pro.present()
                } label: {
                    IconRow(
                        store.entitlement == .none ? "Start Free Trial" : "Subscribe",
                        symbol: "sparkles", color: .retroMustard)
                }
            }
        } footer: {
            Text(
                "Recording and editing are free forever. Cashly Pro adds insights, intelligence, backups and Claude Code."
            )
        }
        Section {
            ManageSubscriptionRow()
            Button {
                Task { await restore() }
            } label: {
                IconRow("Restore Purchases", symbol: "arrow.clockwise", color: .companion)
            }
        } footer: {
            Text("Purchases belong to your Apple Account and work on all your devices.")
        }
        .errorAlert($store.error)
        .alert("Restore Purchases", isPresented: isShowingMessage) {
        } message: {
            Text(message ?? "")
        }
    }

    private var isShowingMessage: Binding<Bool> {
        Binding(get: { message != nil }, set: { if !$0 { message = nil } })
    }

    private func restore() async {
        do {
            try await store.restore()
            message =
                store.entitlement.isActive || !store.owned.isEmpty
                ? String(appLocalized: "Your purchases are back.")
                : String(appLocalized: "No purchases to restore on this Apple Account.")
        } catch {
            store.error = error as? CashlyError
        }
    }
}

private struct ManageSubscriptionRow: View {
    @Environment(StoreModel.self) private var store
    @State private var isManaging = false
    @State private var isRedeeming = false

    var body: some View {
        #if os(iOS) || os(visionOS)
            Button {
                isManaging = true
            } label: {
                IconRow("Manage Subscription", symbol: "creditcard", color: .companion)
            }
            .manageSubscriptionsSheet(isPresented: $isManaging)
        #else
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                Link(destination: url) {
                    IconRow("Manage Subscription", symbol: "creditcard", color: .companion)
                }
            }
        #endif
        Button {
            isRedeeming = true
        } label: {
            IconRow("Redeem Code", symbol: "gift", color: .companion)
        }
        .offerCodeRedemption(options: [], isPresented: $isRedeeming) { _ in
            Task { await store.refresh() }
        }
    }
}
