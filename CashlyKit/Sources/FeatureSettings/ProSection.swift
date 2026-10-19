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
                verbatim: store.planTitle, detail: store.planDetail, symbol: "crown",
                color: .retroMustard)
            if let notice = store.paymentNotice {
                PaymentNoticeRow(notice: notice)
            }
            if let notice = store.renewalNotice {
                RenewalNoticeRow(notice: notice)
            }
            if store.canSubscribe {
                Button {
                    pro.present()
                } label: {
                    IconRow(
                        store.entitlement == .none ? "Start Free Trial" : "Subscribe",
                        symbol: "sparkles", color: .retroMustard)
                }
            }
            if let change = store.planSwitch {
                PlanSwitchRow(change: change)
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

private struct PlanSwitchRow: View {
    @Environment(StoreModel.self) private var store
    let change: PlanSwitch

    var body: some View {
        @Bindable var store = store
        Button {
            store.isConfirmingSwitch = true
        } label: {
            IconRow(
                verbatim: change.title, detail: change.detail,
                symbol: "arrow.triangle.2.circlepath", color: .companion)
        }
        .disabled(store.isBuying)
        .accessibilityIdentifier("pro.switch")
        .sheet(isPresented: $store.isConfirmingSwitch) { PlanSwitchScreen(change: change) }
    }
}

private struct RenewalNoticeRow: View {
    @Environment(\.appTint) private var appTint
    let notice: ProNotice

    var body: some View {
        ManageSubscriptionLink {
            IconRow(
                verbatim: notice.title, detail: notice.detail, symbol: "arrow.clockwise.circle",
                color: appTint)
        }
        .accessibilityIdentifier("pro.renewal")
    }
}

struct PaymentNoticeRow: View {
    let notice: ProNotice

    var body: some View {
        ManageSubscriptionLink {
            IconRow(
                verbatim: notice.title, detail: notice.detail,
                symbol: "exclamationmark.triangle", color: .warning)
        }
        .accessibilityIdentifier("pro.payment")
    }
}

private struct ManageSubscriptionLink<Label: View>: View {
    @ViewBuilder let label: Label
    @State private var isManaging = false

    var body: some View {
        #if os(iOS) || os(visionOS)
            Button {
                isManaging = true
            } label: {
                label
            }
            .manageSubscriptionsSheet(isPresented: $isManaging)
        #else
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                Link(destination: url) { label }
            }
        #endif
    }
}

private struct ManageSubscriptionRow: View {
    @Environment(StoreModel.self) private var store
    @State private var isRedeeming = false

    var body: some View {
        ManageSubscriptionLink {
            IconRow("Manage Subscription", symbol: "creditcard", color: .companion)
        }
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
