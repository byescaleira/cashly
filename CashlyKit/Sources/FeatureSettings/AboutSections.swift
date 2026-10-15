import CashlyDesignSystem
import CashlyResource
import FeatureCore
import StoreKit
import SwiftUI

struct AboutValuesSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        Section {
            IconRow(
                "Private by design", detail: "No servers of its own and no account to create.",
                symbol: "lock", color: .retroDenim)
            IconRow(
                "Your iCloud, your call",
                detail: "Sync goes only through your own iCloud account.", symbol: "icloud",
                color: .retroTeal, value: settings.syncStatus)
            IconRow(
                "No ads, no tracking", detail: "Nothing about you is sold, shared or measured.",
                symbol: "hand.raised", color: .retroOlive)
        } header: {
            Text("What Cashly Stands For").sectionTitle()
        }
    }
}

struct AboutShareSection: View {
    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                VStack(spacing: .spaceXS) {
                    Text("Know someone who'd like Cashly?").font(.titleMedium)
                    Text("Cashly grows by word of mouth, one friend at a time.")
                        .foregroundStyle(.secondary)
                }
                CashlyAnimationView(.about, loops: true)
                    .frame(maxWidth: 200)
                    .accessibilityHidden(true)
                AboutShareButton()
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceS)
        }
    }
}

private struct AboutShareButton: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(AboutModel.self) private var about

    var body: some View {
        if let url = settings.info.appStoreURL {
            ShareLink(
                item: url, message: Text(about.shareMessage),
                preview: SharePreview(
                    "Cashly", image: CashlyResourceImage.appIcon(settings.appIcon.previewName))
            ) {
                label
            }
            .primaryButton()
        } else {
            ShareLink(item: about.shareMessage) { label }
                .primaryButton()
        }
    }

    private var label: some View {
        Label("Share Cashly with a friend", systemImage: "square.and.arrow.up")
    }
}

struct AboutLinksSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            AboutRateRow()
            DisclosureLink {
                WhatsNewScreen()
            } label: {
                IconRow("What's New", symbol: "sparkles", color: .companion)
            }
            ForEach(Array(settings.info.links.enumerated()), id: \.element.id) { index, link in
                Link(destination: link.url) {
                    AboutLinkLabel(
                        title: link.title, symbol: link.symbol,
                        color: index.isMultiple(of: 2) ? appTint : .companion)
                }
            }
        } header: {
            Text("Help and Feedback").sectionTitle()
        }
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
            AboutLinkLabel(title: "Rate Cashly", symbol: "star", color: appTint)
        }
    }
}

struct AboutCreditsSection: View {
    @Environment(AboutModel.self) private var about

    var body: some View {
        Section {
            IconRow(
                "Made by one person in Brazil",
                detail: "Every message reaches the person who writes the code.", symbol: "person",
                color: .retroMustard)
            if let url = about.lottieURL {
                Link(destination: url) {
                    AboutLinkLabel(
                        title: "Lottie by Airbnb", detail: "Animations · Apache License 2.0",
                        symbol: "wand.and.sparkles", color: .retroPlum)
                }
            }
        } header: {
            Text("Credits").sectionTitle()
        } footer: {
            Text("Thank you for trusting Cashly with your month.")
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, .spaceL)
        }
    }
}

private struct AboutLinkLabel: View {
    let title: LocalizedStringKey
    var detail: LocalizedStringKey?
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: .spaceS) {
            IconRow(title, detail: detail, symbol: symbol, color: color)
            Image(systemName: "arrow.up.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
    }
}
