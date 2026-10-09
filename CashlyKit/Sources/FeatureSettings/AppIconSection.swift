import SwiftUI

struct AppIconSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Picker("Ícone", selection: $settings.appIconSelection) {
            ForEach(AppIcon.allCases) { Text($0.title).tag($0) }
        }
    }
}
