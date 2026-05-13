//
//  CashlyProGateModifier.swift
//  CashlyKit
//
//  Reusable Pro-gate. Blurs + locks the wrapped view when the user
//  is on Free tier and routes a tap onto the paywall for the given
//  trigger. Use over individual Pro-only widgets (charts, AI rows,
//  premium reports) so they preview rather than disappear.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyDesignSystem
import CashlyPresentation

public struct CashlyProGateModifier: ViewModifier {
    @Environment(\.router) private var router
    let isPro: Bool
    let trigger: PaywallTrigger
    let blurRadius: CGFloat
    let label: String?

    public func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isPro ? 0 : blurRadius)
                .accessibilityHidden(!isPro)
            if !isPro {
                CashlyButton {
                    router.route(to: .paywall(trigger: trigger))
                } label: {
                    CashlyVStack(spacing: .extraSmall) {
                        CashlySymbol("lock.fill")
                            .cashly(color: .color(.white))
                        CashlyText(label ?? CashlyL10n.string("Unlock with Pro"))
                            .cashly(font: .caption, weight: .semibold)
                            .cashly(color: .color(.white))
                    }
                    .cashlyPadding(.all, .medium)
                    .background(.ultraThinMaterial, in: CashlyShape.rounded(radius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label ?? CashlyL10n.string("Unlock with Pro"))
            }
        }
    }
}

public extension View {
    /// Wraps the view in a Pro gate. When `isPro` is false the view
    /// renders blurred with an unlock overlay that routes to the
    /// paywall for the supplied `trigger`.
    func cashlyProGate(
        isPro: Bool,
        trigger: PaywallTrigger = .upgradeButton,
        blur: CGFloat = 6,
        label: String? = nil
    ) -> some View {
        modifier(CashlyProGateModifier(
            isPro: isPro,
            trigger: trigger,
            blurRadius: blur,
            label: label
        ))
    }
}
