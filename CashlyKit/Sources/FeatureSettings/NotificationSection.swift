import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct NotificationSection: View {
    @Environment(NotificationsModel.self) private var notifications

    var body: some View {
        @Bindable var notifications = notifications
        Section {
            Group {
                Toggle("Bills to Pay and Receive", isOn: $notifications.paymentsToggle)
                Toggle("Month Planning", isOn: $notifications.planningToggle)
            }
            .tint(.positive)
            if notifications.status == .denied, let url = notifications.systemSettingsURL {
                Link("Open Notification Settings", destination: url)
            }
        } footer: {
            Text(notifications.footer)
        }
        .task { await notifications.refreshStatus() }
    }
}
