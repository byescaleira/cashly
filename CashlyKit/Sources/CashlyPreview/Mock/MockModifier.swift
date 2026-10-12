import AppShell
import CashlyData
import CashlyDomain
import CashlyMock
import FeatureSettings
import Foundation
import SwiftUI

struct MockModifier: ViewModifier {
    var includeSampleData = true
    @State private var window: CashlyWindow?
    @State private var settings = SettingsModel.preview
    @State private var error: String?

    func body(content: Content) -> some View {
        Group {
            if let window {
                content.cashlyWindow(window)
                    .cashlySettings(settings)
                    .task {
                        await window.session.refreshUsers()
                        await window.finance.load()
                        await window.intelligence.loadModels(
                            revision: window.finance.datasetRevision)
                    }
            } else if let error {
                Text(error)
            } else {
                ProgressView()
            }
        }
        .task {
            guard window == nil else { return }
            do {
                let database = try await SampleDatabase.make(seeded: includeSampleData)
                try Task.checkCancellation()
                let directory = FileManager.default.temporaryDirectory.appending(
                    path: UUID().uuidString)
                let intelligence = LocalIntelligenceService(directory: directory)
                settings.data = DataModel(backup: database.backup, intelligence: intelligence)
                settings.developer = DeveloperModel(storeURL: nil) {
                    try await SampleDatabase.seed(database)
                }
                window = CashlyWindow(
                    provider: database, intelligence: intelligence, preference: .disabled)
            } catch is CancellationError {} catch { self.error = error.localizedDescription }
        }
    }
}
