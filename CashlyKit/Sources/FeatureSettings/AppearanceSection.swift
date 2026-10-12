import SwiftUI

struct AppearanceSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            LabeledContent("Tema") {
                Picker("Tema", selection: $settings.appearance) {
                    ForEach(Appearance.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden()
            }
            TintRow()
            if settings.supportsAppIcons { AppIconSection() }
        }
    }
}
