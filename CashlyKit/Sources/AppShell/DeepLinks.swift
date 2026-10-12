import FeatureCore
import SwiftUI

struct DeepLinks: ViewModifier {
    @Environment(CashlyNavigation.self) private var navigation
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
    }

    private func handle(_ url: URL) {
        guard url.scheme == "cashly" else { return }
        switch url.host() {
        case "transactions":
            guard let id = url.pathComponents.dropFirst().first else { return }
            if pro.canWrite {
                navigation.open(
                    .addTransaction(id: id == "new" ? nil : id), in: .transaction,
                    beside: horizontalSizeClass == .regular)
            } else {
                navigation.isShowingPaywall = true
            }
        case "budgets":
            navigation.open(.budgets, in: .planning, beside: horizontalSizeClass == .regular)
        default:
            navigation.selectedSection = .home
        }
    }
}
