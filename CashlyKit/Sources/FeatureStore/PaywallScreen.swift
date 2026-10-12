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
        SubscriptionStoreView(productIDs: ShopCatalog.plans.map(\.id)) {
            PaywallHeader()
        }
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .cancellation)
        .modifier(PaywallExtras())
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success) = result {
                await store.refresh()
                dismiss()
            }
        }
        .fontDesign(.rounded)
        .errorAlert($store.error)
    }
}

private struct PaywallExtras: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(PaywallPolicy(kind: .termsOfService, url: StorePolicy.terms))
            .modifier(PaywallPolicy(kind: .privacyPolicy, url: StorePolicy.privacy))
            #if os(visionOS)
                .storeButton(.visible, for: .redeemCode)
            #else
                .subscriptionStoreControlStyle(.prominentPicker)
                .storeButton(.visible, for: .redeemCode)
            #endif
    }
}

private struct PaywallPolicy: ViewModifier {
    let kind: SubscriptionStorePolicyKind
    let url: URL?

    func body(content: Content) -> some View {
        if let url {
            content.subscriptionStorePolicyDestination(url: url, for: kind)
        } else {
            content
        }
    }
}

private struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: .spaceL) {
            SymbolBadge("crown.fill", color: .retroMustard, size: .ring, style: .filled)
            VStack(spacing: .spaceXS) {
                Text("Cashly Pro").font(.titleLarge)
                Text("Try everything free for 7 days.").foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            GuideFeatureList {
                GuideFeature(
                    title: String(appLocalized: "Record and edit without limits"),
                    detail: String(appLocalized: "Transactions, categories, tags and budgets."))
                GuideFeature(
                    title: String(appLocalized: "Analysis and the Journey"),
                    detail: String(appLocalized: "Insights, score, streaks and challenges."))
                GuideFeature(
                    title: String(appLocalized: "Backups, iCloud and Claude Code"),
                    detail: String(
                        appLocalized: "Your data on every device, always with your approval."))
            }
            Text(
                "Without Cashly Pro your data stays visible and exportable, but recording and editing are locked."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .spaceXL)
        .padding(.top, .spaceXL)
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
