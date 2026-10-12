import CashlyDesignSystem
import SwiftUI

struct HelpSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section("Ajuda") {
            if let url = settings.info.reviewURL {
                Link(destination: url) {
                    IconRow("Avaliar o Cashly", symbol: "star", color: appTint)
                }
            }
            if let url = settings.info.supportURL {
                Link(destination: url) {
                    IconRow("Fale conosco", symbol: "envelope", color: .companion)
                }
            }
            if let url = settings.info.helpURL {
                Link(destination: url) {
                    IconRow("Central de ajuda", symbol: "questionmark.circle", color: appTint)
                }
            }
        }
    }
}
