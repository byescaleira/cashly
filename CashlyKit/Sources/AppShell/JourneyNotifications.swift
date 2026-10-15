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
    @Environment(\.pro) private var pro
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.task(id: key) {
            guard store.hasRefreshed, scenePhase == .active, session.user != nil else { return }
            await JourneyNotifier().review(repositories: session.repositories, isActive: isActive)
        }
    }

    private var isActive: Bool {
        pro.canWrite && settings.showsJourney && flags?.isOn(.journey) != false
            && JourneyNotificationSetting.shared.isOn
    }

    private var key: String {
        "\(session.user?.id ?? ""):\(session.generation):\(isActive):\(store.hasRefreshed):\(scenePhase == .active)"
    }
}
