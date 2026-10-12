import SwiftUI

struct JourneySection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle("Show Journey", isOn: $settings.showsJourney)
        } footer: {
            Text(
                "Level, streak, missions, challenges and achievements. Hiding the tab keeps your progress."
            )
        }
    }
}
