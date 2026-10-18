import CashlyDesignSystem
import CashlyWeb
import FeatureCore
import SwiftUI

public struct WebLinkConfirmationScreen: View {
    @Environment(WebSharingModel.self) private var web

    public init() {}

    public var body: some View {
        @Bindable var web = web
        GuideSheet(
            index: 0, count: 1, isWorking: web.isConnecting,
            primary: GuideAction("Show") { Task { await web.connect() } },
            secondary: GuideAction("Cancel") { web.cancelLink() }
        ) {
            GuidePage(
                title: "Show Your Month on This Computer?",
                message:
                    "Cashly sends this month's summary, encrypted for that browser only. It updates when your data changes and ends in 24 hours."
            ) {
                CashlyAnimationView(.connect)
            } content: {
                GuideFeatureList {
                    GuideFeature(
                        title: String(appLocalized: "This month and this profile"),
                        detail: String(
                            appLocalized: "Plan, budgets, bills and recent transactions."),
                        color: .retroTeal)
                    GuideFeature(
                        title: String(appLocalized: "Read-only"),
                        detail: String(appLocalized: "Nothing can be changed from the browser."),
                        color: .retroOrange)
                }
            }
        }
        .errorAlert($web.connectError)
    }
}
