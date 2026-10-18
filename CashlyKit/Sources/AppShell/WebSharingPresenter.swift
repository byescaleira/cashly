import CashlyDomain
import FeatureCore
import FeatureSettings
import SwiftUI

struct WebSharingPresenter: ViewModifier {
    @Environment(SettingsModel.self) private var settings
    @Environment(SessionModel.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.pro) private var pro
    @Environment(\.featureFlags) private var flags
    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        if let web = settings.web {
            @Bindable var web = web
            content
                .sheet(item: $web.pendingLink) { _ in
                    WebLinkConfirmationScreen().environment(web)
                }
                .errorAlert($web.linkError)
                .onChange(of: pro.isPro, initial: true) { web.isPro = $1 }
                .onChange(of: includesJourney, initial: true) { web.includesJourney = $1 }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { web.resume() }
                }
                .onChange(of: refreshKey) { web.scheduleSend(after: .zero) }
        } else {
            content
        }
    }

    private var includesJourney: Bool {
        settings.showsJourney && flags?.isOn(.journey) != false
    }

    private var refreshKey: String {
        "\(session.user?.id ?? ""):\(settings.currency):\(locale.identifier)"
    }
}
