import CashlyDomain
import CloudKit
import CoreTransferable

public struct SharedProfileInvite: Transferable, Sendable {
    let profileID: String
    let title: String
    let service: any ProfileSharing
    let existing: CKShare?

    static let options = CKAllowedSharingOptions(
        allowedParticipantPermissionOptions: .readWrite,
        allowedParticipantAccessOptions: .specifiedRecipientsOnly)

    public static var transferRepresentation: some TransferRepresentation {
        CKShareTransferRepresentation { invite in
            if let share = invite.existing {
                return .existing(
                    share, container: invite.service.container, allowedSharingOptions: options)
            }
            return .prepareShare(
                container: invite.service.container, allowedSharingOptions: options
            ) {
                try await invite.service.share(profileID: invite.profileID, title: invite.title)
            }
        }
    }
}
