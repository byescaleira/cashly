import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct SharedProfilesScreen: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(SessionModel.self) private var session

    var body: some View {
        let profiles = settings.sharedProfiles(in: session.users)
        SettingsPage("Shared Profiles") {
            if profiles.isEmpty {
                SharedProfilesHero()
            } else {
                Section {
                    ForEach(profiles) { profile in
                        DisclosureLink {
                            RouteView(.sharedProfile(id: profile.id))
                        } label: {
                            HStack(spacing: .spaceM) {
                                ProfileAvatar(profile, size: .badgeS + .space2XS)
                                    .accessibilityHidden(true)
                                Text(verbatim: profile.name).foregroundStyle(Color.primary)
                            }
                        }
                    }
                } footer: {
                    Text(
                        "Each one syncs through iCloud with the people you invited. Open one to see who joined, invite more or leave."
                    )
                }
            }
            NewSharedProfileSection()
        }
    }
}

private struct SharedProfilesHero: View {
    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                CashlyAnimationView(.participants).frame(maxWidth: 260)
                VStack(spacing: .space2XS) {
                    Text("Money shared, each on their own device").font(.titleMedium)
                    Text(
                        "Create a profile for the house, the couple or a trip and invite who shares it. Your other profiles stay private."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceS)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct NewSharedProfileSection: View {
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            Button {
                open(.addSharedProfile, in: section)
            } label: {
                IconRow(
                    "New Shared Profile", detail: "Sharing is free and uses your iCloud.",
                    symbol: "person.2.badge.plus", color: appTint)
            }
        }
    }
}
