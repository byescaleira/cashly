import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

public struct SharedProfileScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(SharingModel.self) private var sharing
    @Environment(\.close) private var close
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let profileID: String

    public init(profileID: String) {
        self.profileID = profileID
    }

    public var body: some View {
        @Bindable var sharing = sharing
        let profile = session.user(id: profileID)
        Group {
            #if os(macOS)
                Form { content(profile) }.formStyle(.grouped)
            #else
                AdaptiveList { content(profile) }
            #endif
        }
        .animation(reduceMotion ? nil : .smooth, value: sharing.members)
        .fontDesign(.rounded)
        .navigationTitle("People")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .refreshable { await sharing.refresh(profileID: profileID) }
        .task(id: session.generation) { await sharing.load(profileID: profileID) }
        .task { await sharing.checkAccount() }
        .onChange(of: profile == nil) { _, isGone in
            if isGone { close() }
        }
        .sheet(item: $sharing.confirmation) { confirmation in
            SharingConfirmationScreen(confirmation: confirmation).environment(sharing)
        }
        .errorAlert($sharing.loadError)
    }

    @ViewBuilder private func content(_ profile: User?) -> some View {
        if let profile {
            SharedProfileHero(profile: profile)
            SharedMembersSection(profile: profile)
            SharedSyncSection()
            SharedExitSection(profile: profile)
        }
    }
}

private struct SharedProfileHero: View {
    @Environment(SharingModel.self) private var sharing
    let profile: User

    var body: some View {
        Section {
        } header: {
            VStack(spacing: .spaceM) {
                ProfileAvatar(profile, size: .medallion)
                VStack(spacing: .space2XS) {
                    Text(verbatim: profile.name)
                        .font(.titleMedium)
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(verbatim: sharing.heroMessage(for: profile))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .contentTransition(.numericText(value: sharing.heroCount))
                }
                Chip("Shared", color: .retroTeal, shape: .capsule)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceL)
            .textCase(nil)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct SharedSyncSection: View {
    @Environment(SharingModel.self) private var sharing

    var body: some View {
        Section {
            TimelineView(.everyMinute) { context in
                AdaptiveRow(spacing: .spaceS) {
                    IconRow(
                        verbatim: sharing.syncRowTitle,
                        detail: sharing.syncDetail(at: context.date),
                        symbol: "icloud", color: sharing.syncColor)
                    Chip(sharing.syncTitle, color: sharing.syncColor).fixedSize()
                }
                .accessibilityElement(children: .combine)
            }
        } footer: {
            Text(verbatim: sharing.syncFooter)
        }
    }
}

private struct SharedExitSection: View {
    @Environment(SharingModel.self) private var sharing
    let profile: User

    var body: some View {
        let actions = sharing.exitActions(for: profile)
        if !actions.isEmpty {
            Section {
                ForEach(actions) { action in
                    Button(role: .destructive) {
                        sharing.confirmation = action
                    } label: {
                        IconRow(
                            sharing.action(of: action), symbol: sharing.symbol(of: action),
                            color: .negative, titleColor: .negative)
                    }
                }
            }
        }
    }
}
