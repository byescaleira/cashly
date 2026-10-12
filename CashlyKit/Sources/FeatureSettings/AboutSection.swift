import CashlyDesignSystem
import SwiftUI

struct AboutSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            LabeledContent("Version", value: settings.info.version)
            DisclosureLink {
                WhatsNewScreen()
            } label: {
                IconRow("What's New", symbol: "sparkles", color: appTint)
            }
            if let url = settings.info.privacyURL {
                Link(destination: url) {
                    IconRow("Privacy Policy", symbol: "hand.raised", color: .companion)
                }
            }
            if let url = settings.info.termsURL {
                Link(destination: url) {
                    IconRow("Terms of Use", symbol: "doc.text", color: appTint)
                }
            }
            if let url = settings.info.appStoreURL {
                ShareLink(item: url) {
                    IconRow(
                        "Share Cashly", symbol: "square.and.arrow.up", color: .companion)
                }
            }
        } footer: {
            Text(
                "Cashly has no servers of its own. Your data stays on this device and, with sync turned on, in your iCloud account. Suggestions are calculated on the device itself."
            )
        }
    }
}
