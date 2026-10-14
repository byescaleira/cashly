import CashlyDomain
import FeatureCore
import SwiftUI

struct DeepLinks: ViewModifier {
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(SessionModel.self) private var session
    @Environment(\.pro) private var pro
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        content
            .onOpenURL(perform: handle)
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
        case "budgets":
            navigation.open(.budgets, in: .planning, beside: horizontalSizeClass == .regular)
        case "shop":
            navigation.open(.shop, in: .journey, beside: horizontalSizeClass == .regular)
            navigation.shopItem = url.pathComponents.dropFirst().first.flatMap(ShopItem.init)
        default:
            navigation.selectedSection = .home
        }
    }

    private func open(_ route: Route, in section: AppSection) {
        if pro.canWrite {
            navigation.open(route, in: section, beside: horizontalSizeClass == .regular)
        } else {
            navigation.isShowingPaywall = true
        }
    }
}
