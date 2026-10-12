import CashlyDesignSystem
import SwiftUI

struct HelpSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section("Help") {
            if let url = settings.info.reviewURL {
                Link(destination: url) {
                    IconRow("Rate Cashly", symbol: "star", color: appTint)
                }
            }
            if let url = settings.info.supportURL {
                Link(destination: url) {
                    IconRow("Contact Us", symbol: "envelope", color: .companion)
                }
            }
            if let url = settings.info.helpURL {
                Link(destination: url) {
                    IconRow("Help Center", symbol: "questionmark.circle", color: appTint)
                }
            }
        }
    }
}
