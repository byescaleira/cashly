import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct SharedMembersSection: View {
    @Environment(SharingModel.self) private var sharing
    let profile: User

    var body: some View {
        Section {
            if sharing.canInvite(to: profile), let invite = sharing.invite(for: profile) {
                InviteRow(invite: invite, profile: profile)
            }
            if sharing.isLoadingMembers {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Loading")
            }
            if let notice = sharing.membersNotice {
                IconRow(
                    verbatim: notice, symbol: "exclamationmark.icloud", color: .warning)
            }
            ForEach(sharing.members(of: profile)) { member in
                MemberRow(member: member)
                    .swipeActions(edge: .trailing) {
                        if sharing.canRemove(member) {
                            RemoveButton(member: member, profile: profile)
                        }
                    }
                    .contextMenu {
                        if sharing.canRemove(member) {
                            RemoveButton(member: member, profile: profile)
                        }
                    }
            }
        } footer: {
            Text(verbatim: sharing.membersFooter)
        }
    }
}

private struct RemoveButton: View {
    @Environment(SharingModel.self) private var sharing
    let member: ProfileMember
    let profile: User

    var body: some View {
        Button("Remove", systemImage: "person.badge.minus", role: .destructive) {
            sharing.confirmation = .removeMember(member, profile)
        }
        .tint(.negative)
    }
}

private struct InviteRow: View {
    @Environment(SharingModel.self) private var sharing
    @Environment(\.appTint) private var appTint
    let invite: SharedProfileInvite
    let profile: User

    var body: some View {
        ShareLink(item: invite, preview: SharePreview(profile.name)) {
            IconRow(
                "Invite People", detail: "Messages, Mail, AirDrop or a link.",
                symbol: "person.badge.plus", color: appTint)
        }
        .buttonStyle(.plain)
        .task { await sharing.prepareInvite(for: profile) }
    }
}

private struct MemberRow: View {
    @Environment(SharingModel.self) private var sharing
    let member: ProfileMember

    var body: some View {
        AdaptiveRow(spacing: .spaceS) {
            HStack(spacing: .spaceM) {
                ProfileAvatar(
                    photo: .suggested(for: member.id), initials: member.initials,
                    size: .badgeS + .space2XS
                )
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: sharing.name(of: member)).foregroundStyle(Color.primary)
                    if let detail = sharing.detail(of: member) {
                        Text(verbatim: detail).font(.rowDetail).foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: .spaceS)
            Chip(sharing.badge(of: member), color: sharing.badgeColor(of: member)).fixedSize()
        }
        .accessibilityElement(children: .combine)
    }
}
