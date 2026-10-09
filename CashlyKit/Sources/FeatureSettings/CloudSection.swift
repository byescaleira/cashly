import SwiftUI

struct CloudSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle("Sincronizar com o iCloud", isOn: $settings.isSyncOn)
                .disabled(!settings.isCloudAvailable)
            if settings.isCloudAvailable {
                LabeledContent("Conta", value: settings.cloudAccount.title)
                if settings.syncsAtLaunch {
                    LabeledContent("Última sincronização", value: settings.lastSyncText)
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text(settings.cloudFooter)
        }
    }
}
