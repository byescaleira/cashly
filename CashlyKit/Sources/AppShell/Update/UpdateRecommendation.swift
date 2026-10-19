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
                .task(id: isFree && update.isRecommendationDue) {
                    guard isFree, update.isRecommendationDue else { return }
                    try? await Task.sleep(for: .milliseconds(600))
                    guard !Task.isCancelled else { return }
                    update.offerRecommendation()
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
            GuidePage(verbatim: update.recommendedTitle, message: update.recommendedMessage) {
                CashlyAnimationView(.launch)
            }
        }
        .onAppear { update.recommendationAppeared() }
    }
}
