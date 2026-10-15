import FeatureCore
import FeatureJourney
import FeatureSettings
import FeatureStore
import SwiftUI

struct JourneyNotifications: ViewModifier {
    @Environment(SessionModel.self) private var session
    @Environment(SettingsModel.self) private var settings
    @Environment(StoreModel.self) private var store
    @Environment(\.featureFlags) private var flags
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.task(id: key) {
            guard store.hasRefreshed, scenePhase == .active, session.user != nil else { return }
            await JourneyNotifier().review(repositories: session.repositories, isActive: isActive)
        }
    }

    private var isActive: Bool {
        settings.showsJourney && flags?.isOn(.journey) != false
            && JourneyNotificationSetting.shared.isOn
    }

    private var key: String {
        "\(session.user?.id ?? ""):\(session.generation):\(isActive):\(store.hasRefreshed):\(scenePhase == .active)"
    }
}

extension JourneyNotifier {
    @MainActor
    static func reviewInBackground() async {
        guard FeatureFlags().isOn(.journey),
            let (repositories, _) = try? await CashlyServices.shared.workspace()
        else { return }
        await JourneyNotifier().review(repositories: repositories, isActive: true)
    }
}
