import AppShell
import CashlyData
import CashlyDomain
import Observation
import SwiftUI

@main
struct CashlyApp: App {
    @State private var bootstrap = CashlyBootstrap()
    var body: some Scene {
        WindowGroup { CashlyRootView().environment(bootstrap) }
    }
}

@MainActor @Observable
private final class CashlyBootstrap {
    private(set) var database: CashlyDatabase?
    private(set) var error: String?
    let intelligence = LocalIntelligenceService()
    @ObservationIgnored private var preparation: Task<CashlyDatabase, any Error>?

    func prepare() async {
        guard database == nil else { return }
        error = nil
        let task =
            preparation
            ?? Task.detached(priority: .userInitiated) {
                #if targetEnvironment(simulator)
                    return try CashlyDatabase.open(cloudSync: false)
                #else
                    return try CashlyDatabase.open()
                #endif
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
