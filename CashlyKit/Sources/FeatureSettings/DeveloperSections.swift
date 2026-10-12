import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct DeveloperSections: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        FlagsSection()
        if let developer = settings.developer {
            DeveloperToolsSections().environment(developer)
        }
        if let data = settings.data {
            DeveloperBackupSection().environment(data)
            EraseSection().environment(data)
        }
        DeveloperInfoSection()
    }
}

private struct DeveloperToolsSections: View {
    @Environment(DeveloperModel.self) private var developer

    var body: some View {
        @Bindable var developer = developer
        Group {
            DeveloperDataSection()
            DeveloperNotificationSection()
            DeveloperPreferencesSection()
        }
        .disabled(developer.isWorking)
        .alert("Developer", isPresented: $developer.isShowingMessage) {
        } message: {
            Text(developer.message ?? "")
        }
        .errorAlert($developer.error)
    }
}

private struct DeveloperDataSection: View {
    @Environment(DeveloperModel.self) private var developer
    @Environment(SessionModel.self) private var session: SessionModel?
    @Environment(CashlyNavigation.self) private var navigation: CashlyNavigation?
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            if developer.hasSample {
                Button {
                    Task { await developer.loadSample() }
                } label: {
                    IconRow(
                        "Load Sample Data", symbol: "tray.and.arrow.down", color: appTint)
                }
            }
            if let session {
                Button {
                    session.reload()
                } label: {
                    IconRow("Reload Data", symbol: "arrow.clockwise", color: .companion)
                }
            }
            if let navigation {
                Button {
                    navigation.isOnboarding = true
                } label: {
                    IconRow("Show Welcome", symbol: "hand.wave", color: appTint)
                }
            }
            if developer.isWorking { ProgressView() }
        } header: {
            Text("Data")
        } footer: {
            Text(
                "Sample data adds five users, categories, tags, budgets and transactions to the current records."
            )
        }
    }
}

private struct DeveloperNotificationSection: View {
    @Environment(DeveloperModel.self) private var developer
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            Button {
                Task { await developer.sendTestNotification() }
            } label: {
                IconRow("Send Test Notification", symbol: "bell.badge", color: appTint)
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("The notification arrives five seconds after you tap.")
        }
    }
}

private struct DeveloperPreferencesSection: View {
    @Environment(DeveloperModel.self) private var developer

    var body: some View {
        @Bindable var developer = developer
        Section {
            Button(role: .destructive) {
                developer.isConfirmingReset = true
            } label: {
                IconRow(
                    "Delete Preferences",
                    symbol: "gearshape.arrow.trianglehead.2.clockwise.rotate.90",
                    color: .negative, titleColor: .negative)
            }
            .confirmationDialog(
                "Delete Preferences?", isPresented: $developer.isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { developer.resetPreferences() }
            } message: {
                Text(
                    "Appearance, currency, notifications, backup, features and MCP server go back to their defaults. Your data isn't deleted."
                )
            }
            Button {
                CashlyTips.showAllOnNextLaunch()
            } label: {
                IconRow("Show All Tips on Next Launch", symbol: "lightbulb", color: .companion)
            }
        } header: {
            Text("Preferences")
        } footer: {
            Text("Saved keys: \(developer.preferenceKeys.count).")
        }
    }
}

private struct DeveloperBackupSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            Button {
                Task { await data.backUpNow() }
            } label: {
                IconRow("Back Up Now", symbol: "clock.arrow.circlepath", color: appTint)
            }
            Button {
                data.resetAutoBackupSchedule()
            } label: {
                IconRow(
                    "Reset Automatic Backup Schedule", symbol: "calendar.badge.clock",
                    color: .companion)
            }
            LabeledContent("Destination", value: data.placeTitle)
        } header: {
            Text("Backup")
        } footer: {
            Text(data.autoBackupFooter)
        }
        .disabled(data.isWorking)
        .dataAlerts()
        .task { await data.loadBackups() }
    }
}

private struct DeveloperInfoSection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        Section {
            LabeledContent("Version", value: settings.info.version)
            if let developer = settings.developer {
                LabeledContent("Identifier", value: developer.bundleID)
                DeveloperPath("Database", path: developer.storePath)
            }
            LabeledContent("iCloud Container", value: settings.cloudContainerName)
            LabeledContent("iCloud Account", value: settings.cloudAccount.title)
            LabeledContent(
                "Sync",
                value: settings.isSyncOn ? String(appLocalized: "On") : String(appLocalized: "Off"))
            if let data = settings.data {
                DeveloperPath("Backups on Device", path: data.localPath)
                DeveloperPath(
                    "Backups in iCloud Drive",
                    path: data.cloudPath ?? String(appLocalized: "Unavailable"))
            }
        } header: {
            Text("App")
        }
    }
}

private struct DeveloperPath: View {
    let title: LocalizedStringKey
    let path: String

    init(_ title: LocalizedStringKey, path: String) {
        self.title = title
        self.path = path
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceXS) {
            Text(title)
            Text(verbatim: path)
                .font(.rowDetail.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}
