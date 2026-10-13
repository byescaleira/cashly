import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import StoreKit
import SwiftUI

public struct PaywallScreen: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.appTint) private var appTint

    public init() {}

    public var body: some View {
        @Bindable var store = store
        SubscriptionStoreView(productIDs: ShopCatalog.plans.map(\.id)) {
            PaywallHeader()
                .environment(\.locale, locale)
                .appTint(appTint)
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
        VStack(spacing: .spaceXL) {
            VStack(spacing: .spaceM) {
                CashlyAnimationView(.pro).frame(maxWidth: 220)
                Text("Cashly Pro").font(.titleLarge)
                Chip("Try everything free for 7 days", color: .retroMustard, shape: .capsule)
            }
            .multilineTextAlignment(.center)
            VStack(spacing: .spaceS) {
                PaywallBenefit(
                    "Record and edit without limits",
                    detail: "Transactions, categories, tags and budgets.",
                    symbol: "pencil.and.list.clipboard", color: .retroOrange)
                PaywallBenefit(
                    "Analysis of your money",
                    detail: "Insights, forecasts and the pace of your month.",
                    symbol: "chart.bar.xaxis", color: .retroTeal)
                PaywallBenefit(
                    "The Journey", detail: "Level, streaks, achievements and challenges.",
                    symbol: "trophy.fill", color: .retroMustard)
                PaywallBenefit(
                    "Backups, iCloud and Claude Code",
                    detail: "Your data on every device, always with your approval.",
                    symbol: "icloud.and.arrow.up", color: .retroDenim)
            }
            Text(
                "Without Cashly Pro your data stays visible and exportable, but recording and editing are locked."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .spaceXL)
        .padding(.top, .spaceS)
    }
}

private struct PaywallBenefit: View {
    private let title: LocalizedStringKey
    private let detail: LocalizedStringKey
    private let symbol: String
    private let color: Color

    init(_ title: LocalizedStringKey, detail: LocalizedStringKey, symbol: String, color: Color) {
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge(symbol, color: color, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(title).font(.rowTitle)
                Text(detail).font(.rowDetail).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.spaceM)
        .tintedCard(color)
        .accessibilityElement(children: .combine)
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
