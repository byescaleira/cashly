import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct JourneyReminderSection: View {
    @Environment(SettingsModel.self) private var settings
    @State private var journey = JourneyNotificationSetting.shared

    var body: some View {
        if settings.showsJourney {
            Section {
                Toggle(isOn: $journey.toggle) {
                    SettingsToggleLabel(
                        title: String(appLocalized: "Journey"),
                        detail: String(appLocalized: "Streak, levels, missions and challenges"),
                        symbol: "flame", color: RetroColor.tangerine.color)
                }
                #if os(iOS)
                    Toggle(isOn: $journey.showsLiveActivities) {
                        SettingsToggleLabel(
                            title: String(appLocalized: "Live Activities"),
                            detail: String(
                                appLocalized: "Streak at risk and challenges ending today"),
                            symbol: "timer", color: RetroColor.cherry.color)
                    }
                #endif
            } header: {
                NotificationBanner(
                    text: .streakAtRisk(days: 12),
                    actions: [
                        String(appLocalized: "I Didn't Spend Today"),
                        String(appLocalized: "New Expense"),
                    ]
                )
                .saturation(journey.isOn ? 1 : 0)
                .animation(.smooth, value: journey.isOn)
                .padding(.top, .spaceS)
            }
            .tint(.positive)
        }
    }
}
