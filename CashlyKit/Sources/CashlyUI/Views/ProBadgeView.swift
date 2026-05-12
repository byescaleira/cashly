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
        CashlyButton {
            guard !isPro else { return }
            router.route(to: .paywall(trigger: trigger))
        } label: {
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
        .buttonStyle(.plain)
        .accessibilityLabel(
            isPro
                ? CashlyL10n.string("Cashly Pro active")
                : CashlyL10n.string("Upgrade to Pro")
        )
    }
}
