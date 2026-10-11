import SwiftUI

struct AppearanceSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section("Aparência") {
            Picker("Tema", selection: $settings.appearance) {
                ForEach(Appearance.allCases) { Text($0.title).tag($0) }
            }
            TintRow()
            if settings.supportsAppIcons { AppIconSection() }
        }
    }
}
