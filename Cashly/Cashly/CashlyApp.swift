import AppIntents
import AppShell
import CashlyData
import CashlyDomain
import FeatureCore
import FeatureMCP
import FeatureSettings
import Observation
import SwiftUI

#if DEBUG
    import CashlyMock
#endif

@main
struct CashlyApp: App {
    @State private var settings: SettingsModel
    @State private var bootstrap: CashlyBootstrap
    @State private var lock: AppLockModel

    init() {
        #if targetEnvironment(simulator)
            let settings = SettingsModel(cloudContainer: nil)
            CashlyTips.configure(cloudContainer: nil)
        #else
            let settings = SettingsModel(cloudContainer: CashlyDatabase.cloudContainer)
            CashlyTips.configure(cloudContainer: CashlyDatabase.cloudContainer)
        #endif
        _settings = State(initialValue: settings)
        _bootstrap = State(initialValue: CashlyBootstrap(settings: settings))
        _lock = State(initialValue: AppLockModel(isEnabled: settings.locksApp))
        NotificationResponder.install()
        NewExpenseIntent.open = { CashlyServices.shared.pendingURL = $0 }
    }

    var body: some Scene {
        WindowGroup {
            CashlyRootView()
                .environment(bootstrap)
                .environment(lock)
                .environment(bootstrap.mcp)
                .featureFlags(bootstrap.flags)
                .cashlySettings(settings)
        }
        #if os(macOS)
            Settings {
                NavigationStack { SettingsScreen { MCPSettingsSlot() } }
                    .environment(bootstrap.mcp)
                    .featureFlags(bootstrap.flags)
                    .cashlySettings(settings)
            }
        #endif
    }
}

@MainActor @Observable
private final class CashlyBootstrap {
    private(set) var database: CashlyDatabase?
    private(set) var error: String?
    private(set) var mcp: MCPModel?
    let flags: FeatureFlags
    let intelligence = LocalIntelligenceService()
    private let settings: SettingsModel
    @ObservationIgnored private var isListeningToSync = false

    init(settings: SettingsModel) {
        self.settings = settings
        #if targetEnvironment(simulator)
            flags = FeatureFlags()
        #else
            flags = FeatureFlags(source: CloudKitFlagSource())
        #endif
    }

    private static var deviceName: String {
        #if os(macOS)
            Host.current().localizedName ?? "Cashly"
        #else
            "Cashly"
        #endif
    }

    func prepare() async {
        guard database == nil else { return }
        error = nil
        let cloudSync = settings.syncsAtLaunch
        if cloudSync && !isListeningToSync {
            isListeningToSync = true
            let events = CashlyDatabase.syncEvents()
            Task { [settings] in
                for await date in events { settings.recordSync(date) }
            }
        }
        do {
            let database = try await CashlyServices.shared.database(cloudSync: cloudSync)
            self.database = database
            try? AppGroup.publish(
                AppGroup.Manifest(
                    app: AppGroup.app, bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
                    version: settings.info.version, urlScheme: "cashly",
                    files: [WidgetSnapshotStore.fileName, JourneySnapshotStore.fileName]))
            Task { await flags.refresh() }
            if flags.isOn(.mcpServer) {
                mcp = MCPModel(provider: database, serviceName: Self.deviceName)
            }
            let data = DataModel(
                backup: database.backup, intelligence: intelligence,
                cloud: .container(CashlyDatabase.cloudContainer))
            settings.data = data
            #if DEBUG
                settings.developer = DeveloperModel(
                    storeURL: database.storeURL
                ) { try await SampleDatabase.seed(database) }
                if UserDefaults.standard.bool(forKey: "cashly.developer.seed") {
                    try? await SampleDatabase.seed(database)
                }
            #endif
            Task { await data.runAutoBackupIfNeeded() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct CashlyRootView: View {
    @Environment(CashlyBootstrap.self) private var bootstrap
    @State private var window: CashlyWindow?
    @State private var launch = LaunchProgress()
    @State private var attempt = 0
    var body: some View {
        Group {
            if let window {
                MainScreen().cashlyWindow(window).environment(launch)
            } else if let error = bootstrap.error {
                ContentUnavailableView {
                    Label(
                        "Couldn't open Cashly",
                        systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try Again") { attempt += 1 }
                }
            } else {
                SplashScreen(progress: launch.fraction, status: launch.status)
            }
        }
        .task(id: attempt) {
            guard window == nil else { return }
            await bootstrap.prepare()
            guard !Task.isCancelled else { return }
            if let database = bootstrap.database {
                window = CashlyWindow(
                    provider: database, intelligence: bootstrap.intelligence,
                    flags: bootstrap.flags)
                launch.finish(.database)
            }
        }
    }
}

struct CashlyAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [CashlyIntentsPackage.self] }
}

struct CashlyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "Record a spend in \(.applicationName)",
            ],
            shortTitle: "Add Expense", systemImageName: "plus.circle")
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "Add income in \(.applicationName)",
                "Record income in \(.applicationName)",
            ],
            shortTitle: "Add Income", systemImageName: "arrow.down.left.circle")
        AppShortcut(
            intent: MonthSpentIntent(),
            phrases: [
                "How much did I spend this month in \(.applicationName)",
                "What did I spend in \(.applicationName)",
            ],
            shortTitle: "Spent This Month", systemImageName: "chart.bar")
        AppShortcut(
            intent: CategoryRemainingIntent(),
            phrases: [
                "How much is left in \(.applicationName)",
                "What's left in \(\.$category) in \(.applicationName)",
            ],
            shortTitle: "Left in Category", systemImageName: "gauge.with.dots.needle.33percent")
        AppShortcut(
            intent: MarkBillPaidIntent(),
            phrases: ["Mark a bill as paid in \(.applicationName)"],
            shortTitle: "Mark as Paid", systemImageName: "checkmark.circle")
        AppShortcut(
            intent: CaptureTransactionIntent(),
            phrases: ["Capture a payment in \(.applicationName)"],
            shortTitle: "Capture Payment", systemImageName: "tray.and.arrow.down")
    }
}
