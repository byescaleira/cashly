import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct UpdateRecommendation: ViewModifier {
    @Environment(AppUpdateModel.self) private var update: AppUpdateModel?
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(LaunchProgress.self) private var launch

    func body(content: Content) -> some View {
        if let update {
            @Bindable var update = update
            content
                .sheet(isPresented: $update.isShowingRecommendation, onDismiss: dismissed) {
                    UpdateRecommendedScreen().environment(update)
                }
                .onChange(of: isFree && update.isRecommendationDue, initial: true) { _, due in
                    if due { update.offerRecommendation() }
                }
        } else {
            content
        }
    }

    private var isFree: Bool {
        launch.isDismissed && !navigation.isOnboarding && !navigation.isShowingPaywall
            && navigation.guide == nil && navigation.shopItem == nil
    }

    private func dismissed() {
        update?.dismissRecommendation()
    }
}

struct UpdateRecommendedScreen: View {
    @Environment(AppUpdateModel.self) private var update
    @Environment(\.openURL) private var openURL

    var body: some View {
        GuideSheet(
            index: 0, count: 1,
            primary: GuideAction("Update", isEnabled: update.appStoreURL != nil) {
                if let url = update.appStoreURL { openURL(url) }
                update.dismissRecommendation()
            },
            secondary: GuideAction("Not Now") { update.dismissRecommendation() }
        ) {
            GuidePage(
                title: "A new Cashly is available",
                message: "Update for the latest fixes and improvements. It only takes a moment."
            ) {
                CashlyAnimationView(.launch)
            }
        }
    }
}
