import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct DoneStep: View {
    @Environment(OnboardingModel.self) private var model

    var body: some View {
        GuidePage(
            title: "All Set, \(model.firstName)!",
            message: "Add your first transaction or set budgets in Goals."
        ) {
            CashlyAnimationView(.done)
        } content: {
            GuideFeatureList {
                GuideFeature(
                    title: String(
                        appLocalized: "\(model.suggestions.count) categories ready to use"),
                    color: .positive)
            }
        }
    }
}
