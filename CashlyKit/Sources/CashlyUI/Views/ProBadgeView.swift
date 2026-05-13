//
//  ProBadgeView.swift
//  CashlyKit
//
//  Tiny crown + "Pro" / "Upgrade" pill. Tapping a Free badge routes
//  to the paywall sheet via the active router; tapping a Pro badge
//  is a no-op (settings flow lives elsewhere).
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct ProBadgeView: View {
    @Environment(\.router) private var router

    private let isPro: Bool
    private let trigger: PaywallTrigger

    public init(isPro: Bool, trigger: PaywallTrigger = .upgradeButton) {
        self.isPro = isPro
        self.trigger = trigger
    }

    public var body: some View {
        if isPro {
            badgePill
                // Pro state is a static badge — strip the button role
                // so VoiceOver doesn't promise an interaction the view
                // doesn't deliver.
                .accessibilityElement(children: .combine)
                .accessibilityLabel(CashlyL10n.string("Cashly Pro active"))
                .accessibilityAddTraits(.isStaticText)
        } else {
            CashlyButton {
                router.route(to: .paywall(trigger: trigger))
            } label: {
                badgePill
            }
            .buttonStyle(.plain)
            .accessibilityLabel(CashlyL10n.string("Upgrade to Pro"))
        }
    }

    private var badgePill: some View {
        CashlyHStack(spacing: .extraSmall) {
            CashlySymbol(isPro ? "crown.fill" : "lock.fill")
                .cashly(font: .caption, weight: .bold)
            CashlyText(isPro ? CashlyL10n.string("Pro") : CashlyL10n.string("Upgrade"))
                .cashly(font: .caption, weight: .bold)
        }
        .cashly(color: isPro ? .color(.yellow) : .color(.white))
        .cashlyPadding(.horizontal, .small)
        .cashlyPadding(.vertical, .extraSmall)
        .cashly(background: .color(isPro ? .yellow.opacity(0.15) : .accentColor))
        .cashly(clip: .capsule)
    }
}
