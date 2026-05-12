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
    @Environment(\.router) private var router
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cashly.onboarding.completed") private var completed: Bool = false

    @State private var page: Int = 0

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                freePage.tag(1)
                proPage.tag(2)
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

    private var welcomePage: some View {
        page(
            icon: "wallet.bifold.fill",
            tint: .accentColor,
            title: CashlyL10n.string("Welcome to Cashly"),
            subtitle: CashlyL10n.string("Track budgets, transactions and split with friends.")
        )
    }

    private var freePage: some View {
        page(
            icon: "checkmark.seal.fill",
            tint: .green,
            title: CashlyL10n.string("Start free."),
            subtitle: CashlyL10n.string("1 user, 3 categories, 5 budgets — enough to see if Cashly fits.")
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
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 84))
                .foregroundStyle(tint)
            Text(title)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.top, 80)
    }

    @ViewBuilder
    private var footerBar: some View {
        if page < 2 {
            Button {
                withAnimation { page += 1 }
            } label: {
                Text(CashlyL10n.string("Continue"))
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else {
            VStack(spacing: 12) {
                Button {
                    completed = true
                    dismiss()
                    router.route(to: .paywall(trigger: .upgradeButton))
                } label: {
                    Text(CashlyL10n.string("Upgrade to Pro"))
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.yellow)

                Button {
                    completed = true
                    dismiss()
                } label: {
                    Text(CashlyL10n.string("Continue with Free"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    OnboardingScreen()
}
#endif
