import SwiftUI

struct WhatsNewScreen: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        List(ReleaseNote.current) { note in
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title).font(.headline)
                    Text(note.detail).foregroundStyle(Color.secondary)
                }
            } icon: {
                Image(systemName: note.symbol).foregroundStyle(.tint)
            }
            .padding(.vertical, 4)
        }
        #if os(visionOS)
            .navigationTitle("Novidades da versão " + settings.info.number)
        #else
            .navigationTitle("Novidades")
            .navigationSubtitle("Versão " + settings.info.number)
        #endif
    }
}
