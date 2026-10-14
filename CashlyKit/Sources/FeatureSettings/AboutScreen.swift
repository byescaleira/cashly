import CashlyDesignSystem
import CashlyDomain
import CashlyResource
import FeatureCore
import StoreKit
import SwiftUI

struct AboutScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: .spaceXL) {
                AboutHero()
                AboutStory()
                AboutShare()
                AboutLinks()
                AboutFooter()
            }
            .padding(.horizontal, .spaceInset)
            .padding(.top, .spaceS)
            .padding(.bottom, .spaceXL)
        }
        .readableWidth()
        .background(.groupedBackground)
        .fontDesign(.rounded)
        .navigationTitle("About Cashly")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct AboutHero: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        VStack(spacing: .spaceM) {
            CashlyAnimationView(.about, loops: true).frame(maxWidth: 260)
            Text("Cashly").font(.titleLarge)
            Text("Your whole month, in your pocket").font(.body).foregroundStyle(.secondary)
            Chip("Version \(settings.info.number)", color: appTint, shape: .capsule)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

private struct AboutStory: View {
    @Environment(\.appTint) private var appTint

    var body: some View {
        VStack(spacing: .spaceS) {
            AboutBeat(
                symbol: "chart.bar.fill", color: .retroOlive, title: "Your month at a glance",
                detail:
                    "Budgets, upcoming bills and a forecast of where the month is heading, all on one screen."
            )
            AboutBeat(
                symbol: "plus.circle.fill", color: appTint, title: "Record in a tap",
                detail:
                    "Add an expense in seconds, from the app, Siri or Shortcuts, and split it with whoever shared it."
            )
            AboutBeat(
                symbol: "lock.fill", color: .retroDenim, title: "Your data stays yours",
                detail:
                    "Cashly has no servers of its own. Your data stays on this device and, with sync turned on, in your iCloud account. Suggestions are calculated on the device itself."
            )
            AboutBeat(
                symbol: "person.fill", color: .retroMustard, title: "Made by one person in Brazil",
                detail:
                    "Cashly is designed, built and supported by a single developer. Every suggestion goes straight to the person who writes the code."
            )
        }
    }
}

private struct AboutBeat: View {
    let symbol: String
    let color: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: .spaceM) {
            SymbolBadge(symbol, color: color, size: .badgeL, style: .filled)
            VStack(alignment: .leading, spacing: .space2XS) {
                Text(title).font(.rowTitle)
                Text(detail).font(.rowDetail).foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.spaceL)
        .background(.groupedRow, in: .rect(cornerRadius: .radiusL))
        .accessibilityElement(children: .combine)
    }
}

private struct AboutShare: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        VStack(spacing: .spaceS) {
            if let url = settings.info.appStoreURL {
                ShareLink(
                    item: url, message: Text("I plan my month with Cashly."),
                    preview: SharePreview(
                        "Cashly", image: CashlyResourceImage.appIcon(settings.appIcon.previewName))
                ) {
                    label
                }
                .primaryButton()
            } else {
                ShareLink(item: String(appLocalized: "I plan my month with Cashly.")) { label }
                    .primaryButton()
            }
            Text("Cashly grows by word of mouth, one friend at a time.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var label: some View {
        Label("Share Cashly with a friend", systemImage: "square.and.arrow.up")
    }
}

private struct AboutLinks: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        VStack(spacing: 0) {
            AboutRateRow()
            Divider()
            NavigationLink {
                WhatsNewScreen()
            } label: {
                AboutRow(
                    "What's New", symbol: "sparkles", color: .companion, trailing: "chevron.forward"
                )
            }
            ForEach(settings.info.links) { link in
                Divider()
                Link(destination: link.url) {
                    AboutRow(
                        link.title, symbol: link.symbol,
                        color: link.usesTint ? appTint : .companion,
                        trailing: "arrow.up.right")
                }
            }
        }
        .buttonStyle(.plain)
        .background(.groupedRow, in: .rect(cornerRadius: .radiusGroup))
    }
}

private struct AboutRateRow: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        Button {
            if let url = settings.info.reviewURL { openURL(url) } else { requestReview() }
        } label: {
            AboutRow("Rate Cashly", symbol: "star", color: appTint, trailing: "arrow.up.right")
        }
    }
}

private struct AboutRow: View {
    private let title: LocalizedStringKey
    private let symbol: String
    private let color: Color
    private let trailing: String

    init(_ title: LocalizedStringKey, symbol: String, color: Color, trailing: String) {
        self.title = title
        self.symbol = symbol
        self.color = color
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: .spaceS) {
            IconRow(title, symbol: symbol, color: color)
            Image(systemName: trailing)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, .spaceL)
        .padding(.vertical, .spaceS)
        .frame(minHeight: .rowHeight)
        .contentShape(.rect)
    }
}

private struct AboutFooter: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        VStack(spacing: .space2XS) {
            Text("Version \(settings.info.version)")
            Text("Made in Brazil")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
