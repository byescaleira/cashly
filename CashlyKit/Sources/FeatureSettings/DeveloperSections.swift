import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

struct DeveloperSections: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        DeveloperStatusSection()
        #if DEBUG
            DeveloperStoreSection()
        #endif
        if let developer = settings.developer {
            DeveloperToolsSections().environment(developer)
        }
        FlagsSection()
        if let data = settings.data {
            DeveloperBackupSection().environment(data)
            EraseSection().environment(data)
        }
        DeveloperInfoSection()
    }
}

private struct DeveloperStatusSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.featureFlags) private var flags

    var body: some View {
        Section {
            FlowLayout(spacing: .spaceS) {
                Chip("Development Build", color: .warning, shape: .capsule)
                if let flags {
                    Chip(
                        flags.overridesSummary,
                        color: flags.overriddenCount == 0 ? .secondary : .warning, shape: .capsule)
                }
                DeveloperStoreChip()
                Chip(
                    settings.isSyncOn ? "Sync On" : "Sync Off",
                    color: settings.isSyncOn ? .positive : .secondary, shape: .capsule)
            }
            .padding(.vertical, .space2XS)
        } footer: {
            Text("Everything on this page exists only in development builds.")
        }
    }
}

private struct DeveloperStoreChip: View {
    #if DEBUG
        @Environment(StoreModel.self) private var store

        var body: some View {
            if store.isSimulating {
                Chip(store.simulationStatus, color: .warning, shape: .capsule)
            } else {
                Chip("Real StoreKit", color: .secondary, shape: .capsule)
            }
        }
    #else
        var body: some View { EmptyView() }
    #endif
}

private struct DeveloperToolsSections: View {
    @Environment(DeveloperModel.self) private var developer

    var body: some View {
        @Bindable var developer = developer
        Group {
            DeveloperSimulationSection()
            DeveloperSampleSection()
        }
        .disabled(developer.isWorking)
        .alert("Developer", isPresented: $developer.isShowingMessage) {
        } message: {
            Text(developer.message ?? "")
        }
        .errorAlert($developer.error)
    }
}

private struct DeveloperSimulationSection: View {
    @Environment(DeveloperModel.self) private var developer
    @Environment(CashlyNavigation.self) private var navigation: CashlyNavigation?
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            Button {
                Task { await developer.sendTestNotification() }
            } label: {
                IconRow(
                    "Send Test Notification", detail: "Arrives five seconds after you tap.",
                    symbol: "bell.badge", color: appTint)
            }
            if let navigation {
                Button {
                    navigation.isOnboarding = true
                } label: {
                    IconRow(
                        "Show Welcome", detail: "Opens the onboarding over the current data.",
                        symbol: "hand.wave", color: .companion)
                }
            }
            Button {
                CashlyTips.showAllOnNextLaunch()
            } label: {
                IconRow(
                    "Show All Tips on Next Launch", detail: "Resets every tip that was dismissed.",
                    symbol: "lightbulb", color: appTint)
            }
        } header: {
            Text("Simulations").sectionTitle()
        }
    }
}

private struct DeveloperSampleSection: View {
    @Environment(DeveloperModel.self) private var developer
    @Environment(SessionModel.self) private var session: SessionModel?
    @Environment(\.appTint) private var appTint

    var body: some View {
        @Bindable var developer = developer
        Section {
            if developer.hasSample {
                Button {
                    Task { await developer.loadSample() }
                } label: {
                    IconRow(
                        "Load Sample Data",
                        detail: "Adds five users with categories, tags, budgets and transactions.",
                        symbol: "tray.and.arrow.down", color: appTint)
                }
            }
            if let session {
                Button {
                    session.reload()
                } label: {
                    IconRow("Reload Data", symbol: "arrow.clockwise", color: .companion)
                }
            }
            Button(role: .destructive) {
                developer.isConfirmingReset = true
            } label: {
                IconRow(
                    "Delete Preferences", detail: "Saved keys: \(developer.preferenceKeys.count).",
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
            if developer.isWorking { ProgressView() }
        } header: {
            Text("Sample Data").sectionTitle()
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
                    "Reset Automatic Backup Schedule",
                    detail: "The next copy is made the next time Cashly opens.",
                    symbol: "calendar.badge.clock", color: .companion)
            }
            LabeledContent("Destination", value: data.placeTitle)
        } header: {
            Text("Backup").sectionTitle()
        }
        .disabled(data.isWorking)
        .dataAlerts()
        .task { await data.load() }
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
            if let data = settings.data {
                DeveloperPath("Backups on Device", path: data.localPath)
                DeveloperPath(
                    "Backups in iCloud Drive",
                    path: data.cloudPath ?? String(appLocalized: "Unavailable"))
            }
        } header: {
            Text("App").sectionTitle()
        }
    }
}

#if DEBUG
    private struct DeveloperStoreSection: View {
        @Environment(StoreModel.self) private var store
        @Environment(\.appTint) private var appTint

        var body: some View {
            @Bindable var store = store
            Section {
                Picker("Cashly Pro", selection: $store.simulatedPlan) {
                    ForEach(SimulatedPlan.allCases) { plan in
                        Text(verbatim: plan.title).tag(plan)
                    }
                }
                LabeledContent("Entitlement", value: store.entitlementSummary)
                SettingsRow(
                    "Shop Items", symbol: "bag", color: appTint, value: store.simulatedOwnedSummary
                ) {
                    SettingsPage("Shop Items") { DeveloperShopItemsSection() }
                }
                Button("Reset Simulation", role: .destructive) { store.resetSimulation() }
                    .disabled(!store.isSimulating)
            } header: {
                Text("Shop").sectionTitle()
            } footer: {
                Text("The simulation only exists in development builds and never touches StoreKit.")
            }
        }
    }

    private struct DeveloperShopItemsSection: View {
        @Environment(StoreModel.self) private var store

        var body: some View {
            Section {
                ForEach(StoreModel.simulatedItems) { item in
                    Toggle(isOn: store.ownership(of: item)) {
                        Text(verbatim: item.rawValue).font(.rowDetail.monospaced())
                    }
                }
            } header: {
                Text("Items")
            } footer: {
                Text("Owned: \(store.simulatedOwnedSummary)")
            }
        }
    }

    extension StoreModel {
        fileprivate func ownership(of item: ShopItem) -> Binding<Bool> {
            Binding {
                self.owned.contains(item)
            } set: {
                self.simulate(item, owned: $0)
            }
        }
    }
#endif

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
