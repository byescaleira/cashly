import FeatureCore
import StoreKit
import SwiftUI

struct ManageSubscriptionPresenter: ViewModifier {
    @Environment(CashlyNavigation.self) private var navigation
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        @Bindable var navigation = navigation
        #if os(iOS) || os(visionOS)
            content.manageSubscriptionsSheet(isPresented: $navigation.isManagingSubscription)
        #else
            content.onChange(of: navigation.isManagingSubscription) { _, isManaging in
                guard isManaging else { return }
                navigation.isManagingSubscription = false
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    openURL(url)
                }
            }
        #endif
    }
}
