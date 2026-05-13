//
//  SettingsScreen.swift
//  CashlyKit
//
//  Subscription management + app metadata. Subscription section
//  shows current tier, active plan, renewal/expiry date, hooks into
//  Apple's manageSubscriptionsSheet for cancel/upgrade, and exposes
//  Restore Purchases for users restoring on a new device.
//

import SwiftUI
// `.manageSubscriptionsSheet` is a SwiftUI modifier provided by the
// StoreKit framework. No StoreKit types cross this boundary — the
// import buys exactly that one modifier.
import StoreKit
import CashlyDomain
import CashlyResource
import CashlyPresentation
#if DEBUG
import CashlyMock
#endif

public struct SettingsScreen: CashlyView {
    @Environment(CashlyStore<PaywallState, PaywallAction>.self) var paywallStore
    @Environment(\.mainState) var state
    @Environment(\.paywallState) var paywallState
    @Environment(\.action) var action
    @Environment(\.router) var router
    @State var showManageSheet: Bool = false
    @State var showWipeConfirm: Bool = false

    public init() {}

    public var body: some View {
        Form {
            subscriptionSection
            actionsSection
            appSection
            dangerZoneSection
        }
        .navigationTitle(CashlyL10n.string("Settings"))
        #if os(iOS) || os(visionOS)
        .manageSubscriptionsSheet(isPresented: $showManageSheet)
        #endif
        .cashlyToast(
            isPresented: Binding(
                get: { paywallState.restoreFinishedNoEntitlement },
                set: { newValue in
                    guard newValue == false else { return }
                    paywallStore.cashlyMutate(\.restoreFinishedNoEntitlement, false)
                }
            ),
            message: CashlyL10n.string("Nothing to restore.")
        )
    }

    var subscriptionSection: some View {
        Section {
            CashlyHStack {
                CashlyText(CashlyL10n.string("Tier"))
                CashlySpacer()
                ProBadgeView(isPro: state.isPro)
            }
            if let planId = state.subscriptionStatus.activePlanId {
                CashlyHStack {
                    CashlyText(CashlyL10n.string("Plan"))
                    CashlySpacer()
                    CashlyText(planId)
                        .cashly(color: .textSecondary)
                        .cashly(font: .caption)
                }
            }
            if let expiresAt = state.subscriptionStatus.expiresAt {
                CashlyHStack {
                    CashlyText(state.subscriptionStatus.willAutoRenew
                        ? CashlyL10n.string("Renews")
                        : CashlyL10n.string("Expires"))
                    CashlySpacer()
                    CashlyText(expiresAt.formatted(date: .abbreviated, time: .omitted))
                        .cashly(color: .textSecondary)
                        .cashly(font: .caption)
                }
            }
        } header: {
            CashlyText(CashlyL10n.string("Subscription"))
        }
    }

    var actionsSection: some View {
        Section {
            if state.isPro {
                CashlyButton {
                    showManageSheet = true
                } label: {
                    CashlyLabel(CashlyL10n.string("Manage Subscription"), symbol: "creditcard")
                }
            } else {
                CashlyButton {
                    router.route(to: .paywall(trigger: .upgradeButton))
                } label: {
                    CashlyLabel(CashlyL10n.string("Upgrade to Pro"), symbol: "crown.fill")
                }
                .cashly(tint: .color(.yellow))
            }
            CashlyButton {
                // Restore is a quiet operation — it runs on the
                // existing paywall store, and the global subscription
                // listener flips MainState.subscriptionStatus when the
                // tier changes. The paywall sheet is NOT opened here.
                action(.paywall(.restore))
            } label: {
                CashlyLabel(CashlyL10n.string("Restore Purchases"), symbol: "arrow.clockwise")
            }
        }
    }

    var appSection: some View {
        Section {
            CashlyHStack {
                CashlyText(CashlyL10n.string("Version"))
                CashlySpacer()
                CashlyText(Self.appVersion)
                    .cashly(color: .textSecondary)
                    .cashly(font: .caption)
            }
            .accessibilityElement(children: .combine)
            CashlyHStack {
                CashlyText(CashlyL10n.string("Build"))
                CashlySpacer()
                CashlyText(Self.appBuild)
                    .cashly(color: .textSecondary)
                    .cashly(font: .caption)
            }
            .accessibilityElement(children: .combine)
        } header: {
            CashlyText(CashlyL10n.string("App"))
        }
    }

    var dangerZoneSection: some View {
        Section {
            CashlyButton {
                showWipeConfirm = true
            } label: {
                CashlyLabel(CashlyL10n.string("Delete All Data"), symbol: "trash")
            }
            .cashly(tint: .color(.red))
        } header: {
            CashlyText(CashlyL10n.string("Danger Zone"))
        } footer: {
            CashlyText(CashlyL10n.string("Wipes every local user, category, budget, tag and transaction. CloudKit copies follow on next sync."))
                .cashly(font: .caption)
                .cashly(color: .textSecondary)
        }
        .alert(
            CashlyL10n.string("Confirm wipe prompt"),
            isPresented: $showWipeConfirm
        ) {
            Button(CashlyL10n.string("Cancel"), role: .cancel) {}
            Button(CashlyL10n.string("Delete"), role: .destructive) {
                action(.main(.wipeAllData))
            }
        } message: {
            Text(CashlyL10n.string("This action cannot be undone."))
        }
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private static var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    public static var mock: some View {
        SettingsScreen()
    }
}

#if DEBUG
#Preview {
    NavigationView {
        SettingsScreen
            .cashlyPreview()
    }
}
#endif
