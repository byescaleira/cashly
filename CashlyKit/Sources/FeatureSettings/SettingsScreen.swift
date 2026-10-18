import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

public struct SettingsScreen<Extra: View>: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(NotificationsModel.self) private var notifications
    @Environment(SessionModel.self) private var session: SessionModel?
    @Environment(\.featureFlags) private var flags
    @State private var query = ""
    private let extra: Extra

    public init(@ViewBuilder extra: () -> Extra) {
        self.extra = extra()
    }

    public var body: some View {
        Group {
            #if os(macOS)
                Form { SettingsSections(query: query, extra: extra) }.formStyle(.grouped)
            #else
                AdaptiveList { SettingsSections(query: query, extra: extra) }
                    .searchable(text: $query, prompt: Text("Search Settings"))
            #endif
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) { AddUserButton() }
        }
        .task { await settings.loadCloudAccount() }
        .task { await notifications.refreshStatus() }
        .task(id: session?.generation) {
            guard let session, flags?.isOn(.journey) != false else { return }
            await settings.loadJourney(session: session)
        }
    }
}

extension SettingsScreen where Extra == EmptyView {
    public init() {
        self.init { EmptyView() }
    }
}

private struct SettingsSections<Extra: View>: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(SessionModel.self) private var session: SessionModel?
    @Environment(SharingModel.self) private var sharing: SharingModel?
    @Environment(\.showGuide) private var showGuide
    @Environment(\.featureFlags) private var flags
    let query: String
    let extra: Extra

    var body: some View {
        if query.isEmpty {
            SettingsProfileSection()
            ForEach(SettingsGroup.allCases) { group in
                Section {
                    ForEach(entries(in: group)) { SettingsEntryRow(entry: $0) }
                    if group == .data { extra }
                } header: {
                    Text(verbatim: group.title)
                }
            }
            DevelopmentRow()
        } else {
            SettingsSearchResults(entries: entries(matching: query), query: query)
        }
    }

    private func entries(in group: SettingsGroup? = nil, matching query: String = "")
        -> [SettingsEntry]
    {
        settings.entries(
            in: group, matching: query,
            showsGuides: showGuide != nil && flags?.isOn(.guides) != false,
            showsJourneyEntry: flags?.isOn(.journey) != false,
            showsWebEntry: flags?.isOn(.web) != false,
            showsSharingEntry: session != nil && sharing?.isEnabled == true)
    }
}

private struct SettingsSearchResults: View {
    let entries: [SettingsEntry]
    let query: String

    var body: some View {
        Section {
            if entries.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(entries) { SettingsEntryRow(entry: $0) }
            }
        }
    }
}

private struct DevelopmentRow: View {
    @Environment(\.featureFlags) private var flags

    var body: some View {
        #if DEBUG
            if flags != nil {
                Section {
                    SettingsRow("Developer", symbol: "hammer", color: RetroColor.coffee.color) {
                        SettingsPage("Developer") { DeveloperSections() }
                    }
                }
            }
        #endif
    }
}

private struct AddUserButton: View {
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        Button("Add Profile", systemImage: "person.badge.plus") {
            open(.addUser(id: nil), in: section)
        }
        .tint(Color.primary)
    }
}
