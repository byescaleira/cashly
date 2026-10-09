import AppShell
import CashlyData
import CashlyDomain
import FeatureSettings
import Observation
import SwiftUI

@main
struct CashlyApp: App {
    @State private var settings: SettingsModel
    @State private var bootstrap: CashlyBootstrap

    init() {
        #if targetEnvironment(simulator)
            let settings = SettingsModel(cloudContainer: nil)
        #else
            let settings = SettingsModel(cloudContainer: CashlyDatabase.cloudContainer)
        #endif
        _settings = State(initialValue: settings)
        _bootstrap = State(initialValue: CashlyBootstrap(cloudSync: settings.syncsAtLaunch))
    }

    var body: some Scene {
        WindowGroup { CashlyRootView().environment(bootstrap).cashlySettings(settings) }
        #if os(macOS)
            Settings { SettingsScreen().cashlySettings(settings) }
        #endif
    }
}

@MainActor @Observable
private final class CashlyBootstrap {
    private(set) var database: CashlyDatabase?
    private(set) var error: String?
    let intelligence = LocalIntelligenceService()
    private let cloudSync: Bool
    @ObservationIgnored private var preparation: Task<CashlyDatabase, any Error>?

    init(cloudSync: Bool) {
        self.cloudSync = cloudSync
    }

    func prepare() async {
        guard database == nil else { return }
        error = nil
        let task =
            preparation
            ?? Task.detached(priority: .userInitiated) { [cloudSync] in
                try CashlyDatabase.open(cloudSync: cloudSync)
            }
        preparation = task
        do { database = try await task.value } catch { self.error = error.localizedDescription }
        preparation = nil
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
                        "Não foi possível abrir o Cashly",
                        systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Tentar novamente") { attempt += 1 }
                }
            } else {
                ProgressView("Abrindo Cashly")
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
