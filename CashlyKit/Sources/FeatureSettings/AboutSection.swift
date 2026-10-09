import SwiftUI

struct AboutSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        Section {
            LabeledContent("Versão", value: settings.info.version)
            NavigationLink {
                WhatsNewScreen()
            } label: {
                Label("Novidades", systemImage: "sparkles")
            }
            if let url = settings.info.privacyURL {
                Link(destination: url) {
                    Label("Política de privacidade", systemImage: "hand.raised")
                }
            }
            if let url = settings.info.termsURL {
                Link(destination: url) { Label("Termos de uso", systemImage: "doc.text") }
            }
            if let url = settings.info.appStoreURL {
                ShareLink(item: url) {
                    Label("Compartilhar o Cashly", systemImage: "square.and.arrow.up")
                }
            }
        } header: {
            Text("Sobre")
        } footer: {
            Text(
                "O Cashly não tem servidores próprios. Seus dados ficam neste aparelho e, com a sincronização ligada, na sua conta do iCloud. As sugestões são calculadas no próprio aparelho."
            )
        }
    }
}
