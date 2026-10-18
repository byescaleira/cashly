import CashlyDomain
import FeatureCore
import FeatureSettings
import SwiftUI

struct DeepLinks: ViewModifier {
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(SessionModel.self) private var session
    @Environment(SettingsModel.self) private var settings
    @Environment(\.pro) private var pro

    func body(content: Content) -> some View {
        content
            .onOpenURL(perform: handle)
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = activity.webpageURL { handle(url) }
            }
            .onChange(of: CashlyServices.shared.pendingURL, initial: true) { _, url in
                guard let url else { return }
                CashlyServices.shared.pendingURL = nil
                handle(url)
            }
            .task { handleLaunchArgument() }
    }

    private func handleLaunchArgument() {
        #if DEBUG
            guard let value = UserDefaults.standard.string(forKey: "cashly.developer.openURL"),
                let url = URL(string: value)
            else { return }
            UserDefaults.standard.removeObject(forKey: "cashly.developer.openURL")
            handle(url)
        #endif
    }

    private func handle(_ url: URL) {
        if let web = settings.web {
            switch web.receive(url) {
            case .ignored: break
            case .needsPro:
                pro.present()
                return
            case .invalid, .confirming, .alreadyConnected: return
            }
        }
        guard url.scheme == "cashly" else { return }
        switch url.host() {
        case "transactions":
            guard let id = url.pathComponents.dropFirst().first else { return }
            open(.addTransaction(id: id == "new" ? nil : id), in: .transaction)
        case "captures":
            guard let id = url.pathComponents.dropFirst().first else { return }
            Task {
                guard let capture = try? await session.repositories.captures.capture(id: id),
                    capture.status == .pending
                else { return }
                open(.classifyCapture(capture), in: .transaction)
            }
        case "budgets" where url.pathComponents.dropFirst().first == "new":
            open(
                .addBudget(id: nil, categoryID: nil, date: session.filter.startDate),
                in: .planning)
        case "budgets":
            navigation.open(.budgets, in: .planning)
        case "journey":
            navigation.selectedSection = .journey
        case "shop":
            navigation.open(.shop, in: .journey)
            navigation.shopItem = url.pathComponents.dropFirst().first.flatMap(ShopItem.init)
        default:
            navigation.selectedSection = .home
        }
    }

    private func open(_ route: Route, in section: AppSection) {
        navigation.open(route, in: section)
    }
}
