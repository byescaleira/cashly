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
    #if os(macOS)
        @NSApplicationDelegateAdaptor(CashlyAppDelegate.self) private var delegate
    #else
        @UIApplicationDelegateAdaptor(CashlyAppDelegate.self) private var delegate
    #endif
    @State private var settings: SettingsModel
    @State private var bootstrap: CashlyBootstrap
    @State private var lock: AppLockModel

    init() {
        #if DEBUG && !targetEnvironment(simulator)
            if CommandLine.arguments.contains("-CashlyInitializeCloudSchema") {
                CashlyDatabase.initializeCloudSchema()
            }
        #endif
        #if targetEnvironment(simulator)
            let settings = SettingsModel(
                cloudContainer: nil, rates: CashlyServices.shared.exchangeRates)
            CashlyTips.configure(cloudContainer: nil)
        #else
            let settings = SettingsModel(
                cloudContainer: CashlyDatabase.cloudContainer,
                rates: CashlyServices.shared.exchangeRates)
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
                .environment(bootstrap.update)
                .environment(CashlyServices.shared.sharing)
                .featureFlags(bootstrap.flags)
                .cashlySettings(settings)
        }
        #if os(macOS)
            Settings {
                CashlySettingsWindow()
                    .environment(bootstrap.update)
                    .environment(bootstrap.mcp)
                    .featureFlags(bootstrap.flags)
                    .cashlySettings(settings)
            }
        #endif
    }
}

@MainActor @Observable
private final class CashlyBootstrap {
    private(set) var library: CashlyLibrary?
    private(set) var error: String?
    private(set) var mcp: MCPModel?
    let flags: FeatureFlags
    let update: AppUpdateModel
    private let settings: SettingsModel
    @ObservationIgnored private var isListeningToSync = false

    init(settings: SettingsModel) {
        self.settings = settings
        #if targetEnvironment(simulator)
            flags = FeatureFlags()
            update = AppUpdateModel()
        #else
            flags = FeatureFlags(source: CloudKitFlagSource())
            update = AppUpdateModel(source: CloudKitAppReleaseSource())
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
        guard library == nil else { return }
        error = nil
        if update.isRequired {
            await update.refresh(force: true)
        } else {
            Task { await update.refresh() }
        }
        let isBlocked = update.isRequired
        LegacyIntelligenceFiles.remove()
        let cloudSync = settings.syncsAtLaunch && !isBlocked
        if cloudSync && !isListeningToSync {
            isListeningToSync = true
            let events = CashlyDatabase.syncEvents()
            Task { [settings] in
                for await date in events { settings.recordSync(date) }
            }
        }
        do {
            let library = try await CashlyServices.shared.library(cloudSync: cloudSync)
            let database = library.main
            self.library = library
            try? AppGroup.publish(
                AppGroup.Manifest(
                    app: AppGroup.app, bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
                    version: settings.info.version, urlScheme: "cashly",
                    files: [WidgetSnapshotStore.fileName, JourneySnapshotStore.fileName]))
            Task { await flags.refresh() }
            #if targetEnvironment(simulator)
                CashlyServices.shared.sharing.markUnavailable()
            #else
                if flags.isOn(.social) && !isBlocked {
                    Task { await CashlyServices.shared.startSharing(library) }
                } else {
                    CashlyServices.shared.sharing.markUnavailable()
                }
            #endif
            if flags.isOn(.mcpServer) && !isBlocked {
                mcp = MCPModel(provider: library, serviceName: Self.deviceName)
            }
            let data = DataModel(
                backup: database.backup, cloud: .container(CashlyDatabase.cloudContainer))
            settings.data = data
            #if os(iOS)
                if flags.isOn(.web) && !isBlocked {
                    settings.web = WebSharingModel(provider: library)
                }
            #endif
            #if DEBUG
                settings.developer = DeveloperModel(
                    storeURL: database.storeURL
                ) { try await SampleDatabase.seed(database) }
                if UserDefaults.standard.bool(forKey: "cashly.developer.seed") {
                    try? await SampleDatabase.seed(database)
                }
                if UserDefaults.standard.bool(forKey: "cashly.developer.showcase") {
                    try? await SampleDatabase.seedShowcase(database)
                }
            #endif
            Task {
                if await CashlyServices.shared.isPro() { await data.runAutoBackupIfNeeded() }
            }
            Task { [settings] in await settings.prepareCorrection() }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stopConnections() {
        mcp?.suspend()
        mcp = nil
        settings.web = nil
    }
}

#if os(macOS)
    private struct CashlySettingsWindow: View {
        @Environment(AppUpdateModel.self) private var update

        var body: some View {
            if update.isRequired {
                UpdateRequiredScreen()
            } else {
                NavigationStack { SettingsScreen { MCPSettingsSlot() } }
            }
        }
    }
#endif

private struct CashlyRootView: View {
    @Environment(CashlyBootstrap.self) private var bootstrap
    @Environment(AppUpdateModel.self) private var update
    @Environment(\.scenePhase) private var scenePhase
    @State private var window: CashlyWindow?
    @State private var launch = LaunchProgress()
    @State private var attempt = 0
    var body: some View {
        Group {
            if update.isRequired {
                UpdateRequiredScreen()
            } else if let window {
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
        .onChange(of: update.isRequired) { _, required in
            if required { bootstrap.stopConnections() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await update.refresh() } }
        }
        .task(id: attempt) {
            guard window == nil else { return }
            await bootstrap.prepare()
            guard !Task.isCancelled else { return }
            if let library = bootstrap.library {
                window = CashlyWindow(
                    provider: library, flags: bootstrap.flags)
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
