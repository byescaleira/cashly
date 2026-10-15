import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct NotificationScreen: View {
    @Environment(NotificationsModel.self) private var notifications

    var body: some View {
        SettingsPage("Notifications") {
            NotificationStatusSection()
            ForEach(ReminderKind.allCases) { ReminderSection(kind: $0) }
            JourneyReminderSection()
        }
        .sensoryFeedback(.selection, trigger: notifications.enabledCount)
        .task { await notifications.refreshStatus() }
    }
}

private struct NotificationStatusSection: View {
    @Environment(NotificationsModel.self) private var notifications
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            switch notifications.status {
            case .denied:
                if let url = notifications.systemSettingsURL {
                    Link(destination: url) {
                        IconRow("Open Notification Settings", symbol: "gear", color: appTint)
                    }
                }
            case .notDetermined:
                Button {
                    Task { await notifications.requestAuthorization() }
                } label: {
                    IconRow("Allow Notifications", symbol: "bell.badge", color: appTint)
                }
            case .allowed:
                EmptyView()
            }
        } header: {
            SettingsHero {
                SymbolBadge(notifications.statusSymbol, color: statusColor, size: .badgeXL)
                    .symbolEffect(.bounce, value: notifications.enabledCount)
                    .contentTransition(.symbolEffect(.replace))
                Text(verbatim: notifications.statusTitle)
                    .font(.titleMedium)
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText(value: Double(notifications.enabledCount)))
                Chip(notifications.permissionTitle, color: statusColor, shape: .capsule)
            }
        } footer: {
            Text(verbatim: notifications.statusDetail)
        }
    }

    private var statusColor: Color {
        switch notifications.status {
        case .allowed: .retroOlive
        case .denied: .negative
        case .notDetermined: .secondary
        }
    }
}

private struct ReminderSection: View {
    @Environment(NotificationsModel.self) private var notifications
    let kind: ReminderKind

    var body: some View {
        @Bindable var notifications = notifications
        let isOn = notifications.isOn(kind)
        Section {
            Toggle(isOn: $notifications[dynamicMember: kind.toggle]) {
                SettingsToggleLabel(
                    title: notifications.title(of: kind),
                    detail: notifications.schedule(of: kind), symbol: kind.symbol,
                    color: kind.color.color)
            }
            .tint(.positive)
        } header: {
            NotificationBanner(
                text: notifications.preview(of: kind), actions: notifications.actions(of: kind)
            )
            .saturation(isOn ? 1 : 0)
            .animation(.smooth, value: isOn)
            .padding(.top, .spaceS)
        }
    }
}
