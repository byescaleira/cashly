import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct SharingConfirmationScreen: View {
    @Environment(SharingModel.self) private var sharing
    let confirmation: SharingConfirmation

    var body: some View {
        @Bindable var sharing = sharing
        GuideSheet(
            index: 0, count: 1, isWorking: sharing.isWorking,
            primary: GuideAction(sharing.action(of: confirmation)) {
                Task { await sharing.confirm() }
            },
            secondary: GuideAction("Cancel") { sharing.confirmation = nil }
        ) {
            GuidePage(
                verbatim: sharing.title(of: confirmation),
                message: sharing.message(of: confirmation)
            ) {
                CashlyAnimationView(.privacy)
            }
        }
        .tint(Color.negative)
        .errorAlert($sharing.error)
    }
}
