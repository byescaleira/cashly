import FeatureCore
import SwiftUI

struct NotificationSection: View {
    @Environment(NotificationsModel.self) private var notifications

    var body: some View {
        @Bindable var notifications = notifications
        Section {
            Toggle("Contas a pagar e a receber", isOn: $notifications.paymentsToggle)
            Toggle("Planejamento do mês", isOn: $notifications.planningToggle)
            if notifications.status == .denied, let url = notifications.systemSettingsURL {
                Link("Abrir ajustes de notificações", destination: url)
            }
        } header: {
            Text("Notificações")
        } footer: {
            Text(notifications.footer)
        }
        .task { await notifications.refreshStatus() }
    }
}
