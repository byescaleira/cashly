import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct WhatsNewScreen: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        List(ReleaseNote.current) { note in
            Label {
                VStack(alignment: .leading, spacing: .space2XS) {
                    Text(note.title).font(.headline)
                    Text(note.detail).foregroundStyle(Color.secondary)
                }
            } icon: {
                Image(systemName: note.symbol).foregroundStyle(.tint)
            }
            .padding(.vertical, .space2XS)
        }
        .readableWidth()
        #if os(visionOS)
            .navigationTitle(String(appLocalized: "What's New in Version \(settings.info.number)"))
        #else
            .navigationTitle("What's New")
            .navigationSubtitle(String(appLocalized: "Version \(settings.info.number)"))
        #endif
    }
}
