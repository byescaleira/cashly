import CashlyDesignSystem
import SwiftUI

struct CloudSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle("Sync with iCloud", isOn: $settings.isSyncOn)
                .tint(.positive)
                .disabled(!settings.isCloudAvailable)
            if settings.isCloudAvailable {
                LabeledContent("Account", value: settings.cloudAccount.title)
                if settings.syncsAtLaunch {
                    LabeledContent("Last Sync", value: settings.lastSyncText)
                }
            }
        } footer: {
            Text(settings.cloudFooter)
        }
    }
}
