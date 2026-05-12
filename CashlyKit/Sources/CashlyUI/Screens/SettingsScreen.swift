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
import StoreKit
import CashlyDomain
import CashlyResource
import CashlyPresentation
#if DEBUG
import CashlyMock
#endif

public struct SettingsScreen: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    @State var showManageSheet: Bool = false

    public init() {}

    public var body: some View {
        Form {
            subscriptionSection
            actionsSection
            appSection
        }
        .navigationTitle(CashlyL10n.string("Settings"))
        #if os(iOS) || os(visionOS)
        .manageSubscriptionsSheet(isPresented: $showManageSheet)
        #endif
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
                router.route(to: .paywall(trigger: .upgradeButton))
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
            CashlyHStack {
                CashlyText(CashlyL10n.string("Build"))
                CashlySpacer()
                CashlyText(Self.appBuild)
                    .cashly(color: .textSecondary)
                    .cashly(font: .caption)
            }
        } header: {
            CashlyText(CashlyL10n.string("App"))
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
