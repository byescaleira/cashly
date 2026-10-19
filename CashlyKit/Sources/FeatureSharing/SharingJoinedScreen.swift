import CashlyDesignSystem
import FeatureCore
import SwiftUI

public struct SharingJoinedScreen: View {
    @Environment(SharingModel.self) private var sharing
    @Environment(SessionModel.self) private var session
    private let joined: SharingModel.JoinedProfile

    public init(joined: SharingModel.JoinedProfile) {
        self.joined = joined
    }

    public var body: some View {
        GuideSheet(
            index: 0, count: 1,
            primary: GuideAction("Open Profile") {
                Task { await sharing.open(joined, in: session) }
            },
            secondary: GuideAction("Not Now") { sharing.joined = nil }
        ) {
            GuidePage(
                verbatim: sharing.joinedTitle(joined),
                message: sharing.joinedMessage
            ) {
                CashlyAnimationView(.done)
            }
        }
    }
}
