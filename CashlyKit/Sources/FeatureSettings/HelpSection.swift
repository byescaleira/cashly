import SwiftUI

struct HelpSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        Section("Ajuda") {
            if let url = settings.info.reviewURL {
                Link(destination: url) { Label("Avaliar o Cashly", systemImage: "star") }
            }
            if let url = settings.info.supportURL {
                Link(destination: url) { Label("Fale conosco", systemImage: "envelope") }
            }
            if let url = settings.info.helpURL {
                Link(destination: url) {
                    Label("Central de ajuda", systemImage: "questionmark.circle")
                }
            }
        }
    }
}
