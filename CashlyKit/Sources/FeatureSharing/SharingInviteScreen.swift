import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

public struct SharingInviteScreen: View {
    @Environment(SharingModel.self) private var sharing
    private let profile: User

    public init(profile: User) {
        self.profile = profile
    }

    public var body: some View {
        GuideSheet(
            index: 0, count: 1, primary: primary,
            secondary: GuideAction("Done") { sharing.inviting = nil }
        ) {
            GuidePage(
                title: "Invite Who Shares It",
                message:
                    "Send the invitation by Messages, Mail or AirDrop. When they accept, this profile shows up in their Cashly."
            ) {
                CashlyAnimationView(.participants)
            }
        }
        .task { await sharing.prepareInvite(for: profile) }
    }

    private var primary: GuideAction {
        guard let invite = sharing.invite(for: profile) else {
            return GuideAction("Invite People", isEnabled: false) {}
        }
        return GuideAction("Invite People", sharing: invite, preview: profile.name)
    }
}
