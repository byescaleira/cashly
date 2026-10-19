import CashlyDesignSystem
import CashlyDomain
import Foundation
import SwiftUI

extension SharingModel {
    public func heroMessage(for profile: User) -> String {
        guard let details, details.profileID == profile.id else {
            return String(appLocalized: "Everyone you invite sees and edits this profile.")
        }
        if !details.isOwner {
            guard let owner = details.owner, !owner.name.isEmpty else {
                return String(appLocalized: "Shared with you.")
            }
            return String(appLocalized: "Shared with you by \(owner.name).")
        }
        let count = heroPeople
        if details.joinedOthers > 0 {
            return String(appLocalized: "You share this profile with \(count) people.")
        }
        if count > 0 { return String(appLocalized: "Waiting for \(count) people to accept.") }
        return String(appLocalized: "Only you so far. Invite who shares this money with you.")
    }

    public var heroPeople: Int {
        guard let details else { return 0 }
        return details.joinedOthers > 0 ? details.joinedOthers : details.others.count
    }

    public var heroCount: Double { Double(heroPeople) }

    public var syncRowTitle: String { String(appLocalized: "iCloud") }

    public func canInvite(to profile: User) -> Bool {
        isAvailable && details?.profileID == profile.id && details?.isOwner == true
    }

    public var members: [ProfileMember] { details?.members ?? [] }

    public func members(of profile: User) -> [ProfileMember] {
        details?.profileID == profile.id ? members : []
    }

    public func name(of member: ProfileMember) -> String {
        if member.isCurrentUser { return String(appLocalized: "You") }
        if !member.name.isEmpty { return member.name }
        if let contact = member.contact { return contact }
        return member.status == .joined
            ? String(appLocalized: "Person who joined") : String(appLocalized: "Invited person")
    }

    public func detail(of member: ProfileMember) -> String? {
        guard !member.isCurrentUser, !member.name.isEmpty else { return nil }
        return member.contact
    }

    public func badge(of member: ProfileMember) -> String {
        switch (member.role, member.status) {
        case (.owner, _): String(appLocalized: "Owner")
        case (_, .joined): String(appLocalized: "Joined")
        case (_, .invited): String(appLocalized: "Invited")
        }
    }

    public func badgeColor(of member: ProfileMember) -> Color {
        switch (member.role, member.status) {
        case (.owner, _): .retroTeal
        case (_, .joined): .positive
        case (_, .invited): .retroMustard
        }
    }

    public func canRemove(_ member: ProfileMember) -> Bool {
        details?.isOwner == true && member.role != .owner && !member.isCurrentUser
    }

    public var membersFooter: String {
        let rule = String(
            appLocalized:
                "Everyone here sees and edits this profile's transactions, budgets, categories and tags. Your other profiles stay private."
        )
        guard members.contains(where: canRemove) else { return rule }
        return rule + " " + String(appLocalized: "Swipe left on someone to remove them.")
    }

    public var isLoadingMembers: Bool { details == nil && isLoading }

    public var membersNotice: String? {
        guard details == nil, !isLoading else { return nil }
        if !isEnabled {
            return String(appLocalized: "Shared profiles are turned off on this device for now.")
        }
        guard hasFailedLoading else { return nil }
        return String(appLocalized: "Couldn't load who is in this profile. Pull down to try again.")
    }

    public func exitActions(for profile: User) -> [SharingConfirmation] {
        guard let details, details.profileID == profile.id else { return [] }
        guard details.isOwner else { return [.leave(profile)] }
        let stop: [SharingConfirmation] =
            details.isShared && !details.others.isEmpty ? [.stopSharing(profile)] : []
        return stop + [.deleteForEveryone(profile)]
    }

    public func symbol(of confirmation: SharingConfirmation) -> String {
        switch confirmation {
        case .leave: "rectangle.portrait.and.arrow.right"
        case .stopSharing: "person.2.slash"
        case .deleteForEveryone: "trash"
        case .removeMember: "person.badge.minus"
        }
    }

    public var settingsURL: URL? {
        #if os(iOS)
            URL(string: UIApplication.openSettingsURLString)
        #else
            nil
        #endif
    }

    public var joinedMessage: String {
        String(
            appLocalized:
                "It's in your profile menu, next to your own. What anyone records shows up for everyone."
        )
    }

    public var syncTitle: String {
        switch status.phase {
        case .syncing: String(appLocalized: "Syncing")
        case .failed: String(appLocalized: "Couldn't sync")
        case .idle:
            status.lastSync == nil
                ? String(appLocalized: "Waiting for iCloud") : String(appLocalized: "Up to date")
        }
    }

    public var syncColor: Color {
        switch status.phase {
        case .syncing: .info
        case .failed: .negative
        case .idle: status.lastSync == nil ? .secondary : .positive
        }
    }

    public func syncDetail(at now: Date) -> String {
        guard let lastSync = status.lastSync else {
            return String(appLocalized: "Changes go out as soon as iCloud is reachable.")
        }
        let relative = min(lastSync, now).formatted(
            .relative(presentation: .named).locale(.app))
        return String(appLocalized: "Last synced \(relative)")
    }

    public var syncFooter: String {
        String(
            appLocalized:
                "Changes travel through iCloud and are end-to-end encrypted with Advanced Data Protection. Cashly never sees them."
        )
    }

    public func title(of confirmation: SharingConfirmation) -> String {
        switch confirmation {
        case .leave(let user): String(appLocalized: "Leave \(user.name)?")
        case .stopSharing: String(appLocalized: "Stop Sharing?")
        case .deleteForEveryone(let user): String(appLocalized: "Delete \(user.name) for Everyone?")
        case .removeMember(let member, _): String(appLocalized: "Remove \(name(of: member))?")
        }
    }

    public func message(of confirmation: SharingConfirmation) -> String {
        switch confirmation {
        case .leave:
            String(
                appLocalized:
                    "The profile leaves this device. Its data stays with the others, and they can invite you again."
            )
        case .stopSharing:
            String(
                appLocalized:
                    "Everyone else loses access. The profile and its data stay with you, and you can invite again."
            )
        case .deleteForEveryone:
            String(
                appLocalized:
                    "The profile and all of its data are deleted from iCloud, for you and everyone you invited."
            )
        case .removeMember:
            String(
                appLocalized:
                    "They lose access to this profile right away. What they recorded stays here.")
        }
    }

    public func action(of confirmation: SharingConfirmation) -> LocalizedStringKey {
        switch confirmation {
        case .leave: "Leave Profile"
        case .stopSharing: "Stop Sharing"
        case .deleteForEveryone: "Delete for Everyone"
        case .removeMember: "Remove"
        }
    }
}

extension SharingModel {
    public func joinedTitle(_ joined: JoinedProfile) -> String {
        joined.title.isEmpty
            ? String(appLocalized: "You Joined a Shared Profile")
            : String(appLocalized: "You Joined \(joined.title)")
    }
}
