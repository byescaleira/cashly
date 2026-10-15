import FeatureCore
import FeatureJourney
import FeatureSettings
import SwiftUI

struct JourneyNotifications: ViewModifier {
    @Environment(SessionModel.self) private var session
    @Environment(SettingsModel.self) private var settings
    @Environment(\.featureFlags) private var flags
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.task(id: key) {
            guard scenePhase == .active, session.user != nil else { return }
            await JourneyNotifier().review(repositories: session.repositories, isActive: isActive)
        }
    }

    private var isActive: Bool {
        settings.showsJourney && flags?.isOn(.journey) != false
            && JourneyNotificationSetting.shared.isOn
    }

    private var key: String {
        "\(session.user?.id ?? ""):\(session.generation):\(isActive):\(scenePhase == .active)"
    }
}

extension JourneyNotifier {
    @MainActor
    static func reviewInBackground() async {
        guard FeatureFlags().isOn(.journey),
            let (repositories, _) = try? await CashlyServices.shared.workspace()
        else { return }
        await JourneyNotifier().review(
            repositories: repositories, isActive: SettingsModel.journeyPreference)
    }
}
