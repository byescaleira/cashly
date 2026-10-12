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
    }

    var body: some Scene {
        WindowGroup {
            CashlyRootView()
                .environment(bootstrap)
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
    @State private var attempt = 0
    var body: some View {
        Group {
            if let window {
                MainScreen().cashlyWindow(window)
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
                LaunchView()
            }
        }
        .task(id: attempt) {
            guard window == nil else { return }
            await bootstrap.prepare()
            guard !Task.isCancelled else { return }
            if let database = bootstrap.database {
                window = CashlyWindow(provider: database, intelligence: bootstrap.intelligence)
            }
        }
    }
}
