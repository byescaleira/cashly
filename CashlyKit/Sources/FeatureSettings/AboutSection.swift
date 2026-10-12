import CashlyDesignSystem
import SwiftUI

struct AboutSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            LabeledContent("Versão", value: settings.info.version)
            DisclosureLink {
                WhatsNewScreen()
            } label: {
                IconRow("Novidades", symbol: "sparkles", color: appTint)
            }
            if let url = settings.info.privacyURL {
                Link(destination: url) {
                    IconRow("Política de privacidade", symbol: "hand.raised", color: .companion)
                }
            }
            if let url = settings.info.termsURL {
                Link(destination: url) {
                    IconRow("Termos de uso", symbol: "doc.text", color: appTint)
                }
            }
            if let url = settings.info.appStoreURL {
                ShareLink(item: url) {
                    IconRow(
                        "Compartilhar o Cashly", symbol: "square.and.arrow.up", color: .companion)
                }
            }
        } footer: {
            Text(
                "O Cashly não tem servidores próprios. Seus dados ficam neste aparelho e, com a sincronização ligada, na sua conta do iCloud. As sugestões são calculadas no próprio aparelho."
            )
        }
    }
}
