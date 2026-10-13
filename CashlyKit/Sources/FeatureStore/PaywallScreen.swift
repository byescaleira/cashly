import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import StoreKit
import SwiftUI

public struct PaywallScreen: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        @Bindable var store = store
        NavigationStack {
            ScrollView {
                VStack(spacing: .spaceXL) {
                    PaywallHero()
                    PaywallComparison()
                    if let days = store.trialDays { PaywallTimeline(days: days) }
                    PaywallPlans()
                }
                .padding(.horizontal, .spaceInset)
                .padding(.bottom, .spaceXL)
            }
            .readableWidth()
            .safeAreaBar(edge: .bottom) { PaywallBar() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .fontDesign(.rounded)
        .interactiveDismissDisabled(store.isBuying)
        .errorAlert($store.error)
        #if os(macOS)
            .frame(minWidth: 520, minHeight: 720)
        #endif
    }
}

private struct PaywallHero: View {
    @Environment(StoreModel.self) private var store

    var body: some View {
        VStack(spacing: .spaceM) {
            CashlyAnimationView(.paywall).frame(maxWidth: 260)
            Text("Cashly Pro").font(.titleLarge)
            Text("Your whole month, without limits").font(.body).foregroundStyle(.secondary)
            if let days = store.trialDays {
                Chip("\(days) days free, cancel anytime", color: .retroMustard, shape: .capsule)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

private struct PaywallBar: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingNothingToRestore = false

    var body: some View {
        VStack(spacing: .spaceS) {
            Button {
                Task { if await store.subscribe() { dismiss() } }
            } label: {
                ZStack {
                    Text(title).opacity(store.isBuying ? 0 : 1)
                    if store.isBuying { ProgressView() }
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
            }
            .prominentButton()
            .controlSize(.large)
            .disabled(store.selected == nil || store.isBuying)
            if let plan = store.selected {
                Text(store.trialDays == nil ? plan.billing : plan.billingAfterTrial)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if store.isPending {
                Text("Waiting for approval from your family organizer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            PaywallLinks(restore: restore)
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

    private var title: LocalizedStringKey {
        if let days = store.trialDays { "Start \(days)-day free trial" } else { "Subscribe" }
    }

    private func restore() async {
        if await store.restoreSubscription() {
            dismiss()
        } else if store.error == nil {
            isShowingNothingToRestore = true
        }
    }
}

private struct PaywallLinks: View {
    @Environment(StoreModel.self) private var store
    @State private var isRedeeming = false
    let restore: () async -> Void

    var body: some View {
        HStack(spacing: .spaceS) {
            Button("Restore") { Task { await restore() } }
            #if os(iOS) || os(visionOS)
                Text(verbatim: "·")
                Button("Redeem Code") { isRedeeming = true }
                    .offerCodeRedemption(options: [], isPresented: $isRedeeming) { _ in
                        Task { await store.refresh() }
                    }
            #endif
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

enum StorePolicy {
    static var terms: URL? { url("CashlyTermsURL") }
    static var privacy: URL? { url("CashlyPrivacyURL") }

    private static func url(_ key: String) -> URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty
        else { return nil }
        return URL(string: value)
    }
}
