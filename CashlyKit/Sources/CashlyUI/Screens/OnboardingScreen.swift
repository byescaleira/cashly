//
//  OnboardingScreen.swift
//  CashlyKit
//
//  First-launch flow. 3 paged steps: Welcome, Free tier intro, Pro
//  tier teaser. The last step CTA either dismisses (Continue with
//  Free) or pushes the paywall via the active router. Completion
//  persists in @AppStorage("cashly.onboarding.completed") so the
//  app delegate can decide whether to present the screen at launch.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct OnboardingScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("cashly.onboarding.completed") private var completed: Bool = false

    /// Invoked when the user taps "Upgrade to Pro" on the last page.
    /// Owned by CashlyApp so the route lands on the same handler that
    /// `onOpenURL` uses (the MainScreen `pendingDeeplink` channel) —
    /// the screen's own @Environment(\.router) is an orphan because
    /// the fullScreenCover hosts OnboardingScreen outside MainScreen.
    private let onUpgrade: () -> Void

    @State private var page: Int = 0

    public init(onUpgrade: @escaping () -> Void = {}) {
        self.onUpgrade = onUpgrade
    }

    public var body: some View {
        CashlyVStack(spacing: .zero) {
            TabView(selection: $page) {
                welcomePage
                    .tag(0)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(pageLabel(index: 0))
                freePage
                    .tag(1)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(pageLabel(index: 1))
                proPage
                    .tag(2)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(pageLabel(index: 2))
            }
            #if os(iOS) || os(visionOS)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            #endif

            footerBar
                .cashlyPadding(.horizontal, .large)
                .cashlyPadding(.bottom, .large)
        }
    }

    /// Announces "Page N of 3, <title>" to VoiceOver users so they
    /// know how many pages exist and where they are in the flow.
    private func pageLabel(index: Int) -> String {
        let titles = [
            CashlyL10n.string("Welcome to Cashly"),
            CashlyL10n.string("Start free."),
            CashlyL10n.string("Unlock Cashly Pro.")
        ]
        return String(
            format: CashlyL10n.string("Page %lld of %lld, %@"),
            index + 1,
            titles.count,
            titles[index]
        )
    }

    private var welcomePage: some View {
        page(
            icon: "wallet.bifold.fill",
            tint: .accentColor,
            title: CashlyL10n.string("Welcome to Cashly"),
            subtitle: CashlyL10n.string("Track budgets, transactions and split with friends.")
        )
    }

    private var freePage: some View {
        let limits = MainState.freeLimits
        let subtitle = String(
            format: CashlyL10n.string("%lld user, %lld categories, %lld budgets — enough to see if Cashly fits."),
            limits.maxUsers,
            limits.maxCategories,
            limits.maxBudgets
        )
        return page(
            icon: "checkmark.seal.fill",
            tint: .green,
            title: CashlyL10n.string("Start free."),
            subtitle: subtitle
        )
    }

    private var proPage: some View {
        page(
            icon: "crown.fill",
            tint: .yellow,
            title: CashlyL10n.string("Unlock Cashly Pro."),
            subtitle: CashlyL10n.string("Unlimited users, categories, budgets and AI predictions.")
        )
    }

    @ViewBuilder
    private func page(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String
    ) -> some View {
        CashlyVStack(spacing: .large) {
            CashlySymbol(icon)
                .cashly(font: .system(.largeTitle).weight(.bold))
                .imageScale(.large)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            CashlyText(title)
                .cashly(font: .title, weight: .bold)
                .cashly(alignment: .center)
            CashlyText(subtitle)
                .cashly(font: .body)
                .cashly(color: .textSecondary)
                .cashly(alignment: .center)
                .cashlyPadding(.horizontal, .large)
            CashlySpacer()
        }
        .cashlyPadding(.top, .ultraLarge)
    }

    @ViewBuilder
    private var footerBar: some View {
        if page < 2 {
            CashlyButton {
                advancePage()
            } label: {
                CashlyText(CashlyL10n.string("Continue"))
                    .cashly(font: .headline, weight: .semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else {
            CashlyVStack(spacing: .medium) {
                CashlyButton {
                    onUpgrade()
                    completed = true
                } label: {
                    CashlyText(CashlyL10n.string("Upgrade to Pro"))
                        .cashly(font: .headline, weight: .semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.yellow)

                CashlyButton {
                    completed = true
                } label: {
                    CashlyText(CashlyL10n.string("Continue with Free"))
                        .cashly(font: .subheadline, weight: .semibold)
                        .cashly(color: .textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(.rect)
                }
            }
        }
    }

    /// Advances the carousel, honouring the user's
    /// `accessibilityReduceMotion` preference (no animation when on).
    private func advancePage() {
        if reduceMotion {
            page += 1
        } else {
            withAnimation { page += 1 }
        }
    }
}

#if DEBUG
#Preview {
    OnboardingScreen()
}
#endif
