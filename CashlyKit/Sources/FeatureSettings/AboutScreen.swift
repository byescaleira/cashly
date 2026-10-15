import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

struct AboutScreen: View {
    @Environment(SessionModel.self) private var session

    var body: some View {
        ModelHost(AboutModel(session: session)) { AboutPage() }
    }
}

private struct AboutPage: View {
    @Environment(AboutModel.self) private var about
    @Environment(SessionModel.self) private var session

    var body: some View {
        SettingsPage("About Cashly") {
            AboutHeroSection()
            AboutFiguresSection()
            AboutValuesSection()
            AboutShareSection()
            AboutLinksSection()
            AboutCreditsSection()
        }
        .task(id: session.generation) { await about.load() }
    }
}

private struct AboutHeroSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(StoreModel.self) private var store
    @Environment(AboutModel.self) private var about
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    var body: some View {
        let plan = about.plan(for: store.entitlement)
        Section {
            VStack(spacing: .spaceM) {
                AppIconImage(icon: settings.appIcon, size: .badgeXL * 1.5)
                    .shadow(color: .black.opacity(.opacityTint), radius: 10, y: 4)
                    .scaleEffect(isShown || reduceMotion ? 1 : 0.7)
                    .opacity(isShown || reduceMotion ? 1 : 0)
                VStack(spacing: .space2XS) {
                    Text(verbatim: "Cashly").font(.titleLarge)
                    Text("Version \(settings.info.version)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Chip(plan.title, color: plan.isPro ? .retroMustard : .secondary, shape: .capsule)
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceM)
            .animation(reduceMotion ? nil : .bouncy, value: isShown)
            .animation(reduceMotion ? nil : .smooth, value: plan)
            .accessibilityElement(children: .combine)
            .task { isShown = true }
        }
    }
}

private struct AboutFiguresSection: View {
    @Environment(AboutModel.self) private var about
    @Environment(SettingsModel.self) private var settings
    @Environment(\.featureFlags) private var flags

    var body: some View {
        Section {
            if about.isEmpty {
                IconRow(
                    "Your story starts with the first record",
                    detail: "Your numbers show up here as you use Cashly.", symbol: "sparkles",
                    color: .retroOlive)
            } else {
                AboutFigureGrid(
                    figures: about.figures(
                        showingJourney: settings.showsJourney && flags?.isOn(.journey) != false))
            }
        } header: {
            Text("Your Cashly").sectionTitle()
        } footer: {
            Text("Counted on this device from your own records.")
        }
    }
}

private struct AboutFigureGrid: View {
    @Environment(AboutModel.self) private var about
    @ScaledMetric private var tileWidth: CGFloat = 140
    let figures: [AboutFigure]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: tileWidth), spacing: .spaceS)],
            spacing: .spaceS
        ) {
            ForEach(figures) { AboutFigureTile(figure: $0) }
        }
        .padding(.vertical, .space2XS)
        .redacted(reason: about.hasLoaded ? [] : .placeholder)
    }
}

private struct AboutFigureTile: View {
    @Environment(AboutModel.self) private var about
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let figure: AboutFigure

    var body: some View {
        VStack(alignment: .leading, spacing: .space2XS) {
            Image(systemName: figure.kind.symbol)
                .font(.icon(.s, weight: .semibold))
                .foregroundStyle(figure.kind.color)
                .symbolEffect(
                    .bounce, options: .nonRepeating, value: !reduceMotion && about.hasLoaded
                )
                .padding(.bottom, .space2XS)
            Text(figure.value)
                .font(.amountTitle)
                .contentTransition(.numericText(value: figure.numeric))
                .amountLine()
            Text(figure.caption).font(.subheadline.weight(.semibold))
            Text(figure.detail).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.spaceM)
        .tintedCard(figure.kind.color)
        .animation(reduceMotion ? nil : .smooth, value: figure)
        .accessibilityElement(children: .combine)
    }
}

extension AboutFigure.Kind {
    fileprivate var color: Color {
        switch self {
        case .history: .retroDenim
        case .transactions: .retroOrange
        case .days: .retroOlive
        case .level: .retroMustard
        case .budgets: .retroTeal
        }
    }
}
