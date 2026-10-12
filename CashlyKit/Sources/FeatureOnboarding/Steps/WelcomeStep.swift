import FeatureCore
import SwiftUI

struct WelcomeStep: View {
    var body: some View {
        GuidePage(
            title: "Welcome to Cashly",
            message:
                "Organize spending, budgets and goals in one place, with your data kept on your device."
        ) {
            CashlyAnimationView(.month)
        }
    }
}
