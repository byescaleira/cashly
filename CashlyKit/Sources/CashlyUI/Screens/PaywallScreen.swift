//
//  PaywallScreen.swift
//  CashlyKit
//
//  Subscription upgrade sheet. Presented when the user hits a Free
//  tier limit, taps the Intelligence tab, or hits an explicit
//  Upgrade button. The screen is purely UI — purchase flow lives in
//  PaywallMiddleware, plans / status snapshots come from
//  SubscriptionUseCase via the store. Auto-dismisses on
//  purchaseSucceeded.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation
#if DEBUG
import CashlyMock
#endif

public struct PaywallScreen: CashlyView {
    @Environment(CashlyStore<PaywallState, PaywallAction>.self) var store
    @Environment(\.paywallState) var state
    @Environment(\.action) var action
    @Environment(\.dismiss) var dismiss

    public init() {}

    public var body: some View {
        Form {
            headerSection
            plansSection
            purchaseSection
            restoreSection
        }
        .task { action(.paywall(.fetch)) }
        .onChange(of: state.didPurchase) { _, newValue in
            if newValue { dismiss() }
        }
    }

    var headerSection: some View {
        Section {} header: {
            CashlyVStack(alignment: .center, spacing: .medium) {
                CashlySymbol("crown.fill")
                    .cashly(font: .largeTitle, weight: .bold)
                    .cashly(color: .color(.yellow))
                    .accessibilityHidden(true)

                CashlyText(headline)
                    .cashly(font: .title2, weight: .bold)
                    .cashly(alignment: .center)

                CashlyText(subhead)
                    .cashly(font: .subheadline)
                    .cashly(color: .textSecondary)
                    .cashly(alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .cashlyPadding(.vertical, .large)
        }
    }

    var plansSection: some View {
        Section {
            if state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .cashlyPadding()
                    .accessibilityLabel(CashlyL10n.string("Loading plans"))
            } else if state.plans.isEmpty {
                CashlyText(CashlyL10n.string("Plans unavailable — try again."))
                    .cashly(color: .textSecondary)
            } else {
                ForEach(state.plans, id: \.id) { plan in
                    planRow(plan)
                }
            }
        } header: {
            CashlyText(CashlyL10n.string("Choose your plan"))
                .cashly(font: .headline)
        }
    }

    @ViewBuilder
    func planRow(_ plan: SubscriptionPlan) -> some View {
        let isSelected = state.selectedPlanId == plan.id
        CashlyButton {
            action(.paywall(.select(planId: plan.id)))
        } label: {
            CashlyHStack {
                CashlyVStack(alignment: .leading) {
                    CashlyText(plan.displayName)
                        .cashly(font: .body, weight: .semibold)
                    if let period = plan.period {
                        CashlyText(period.capitalized)
                            .cashly(font: .caption)
                            .cashly(color: .textSecondary)
                    }
                }
                CashlySpacer()
                CashlyText(plan.displayPrice)
                    .cashly(font: .body, weight: .bold)
                CashlySymbol(isSelected ? "checkmark.circle.fill" : "circle")
                    .cashly(color: isSelected ? .primary : .textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    var purchaseSection: some View {
        Section {} footer: {
            CashlyButton {
                action(.paywall(.purchase))
            } label: {
                CashlyHStack {
                    if state.isPurchasing {
                        ProgressView()
                            .accessibilityLabel(CashlyL10n.string("Purchasing"))
                    }
                    CashlyText(CashlyL10n.string("Continue"))
                        .cashly(font: .headline, weight: .semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(state.selectedPlanId == nil || state.isPurchasing)
            .cashly(tint: state.selectedPlanId == nil ? .disabled : .primary)
        }
    }

    var restoreSection: some View {
        Section {} footer: {
            CashlyButton {
                action(.paywall(.restore))
            } label: {
                CashlyText(CashlyL10n.string("Restore Purchases"))
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .disabled(state.isPurchasing)
        }
    }

    private var headline: String {
        switch state.trigger {
        case .limitReached: return CashlyL10n.string("You've hit the free limit.")
        case .intelligenceTab: return CashlyL10n.string("AI features require Pro.")
        case .upgradeButton: return CashlyL10n.string("Unlock Cashly Pro.")
        }
    }

    private var subhead: String {
        CashlyL10n.string("Unlimited users, categories, budgets and AI predictions.")
    }

    public static var mock: some View {
        PaywallScreen()
    }
}

#if DEBUG
#Preview {
    PaywallScreen
        .cashlyPreview()
}
#endif
