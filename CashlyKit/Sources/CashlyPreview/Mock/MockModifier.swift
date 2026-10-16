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
                        await window.intelligence.load()
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
                settings.data = DataModel(backup: database.backup)
                settings.developer = DeveloperModel(storeURL: nil) {
                    try await SampleDatabase.seed(database)
                }
                window = CashlyWindow(
                    provider: database, preference: .disabled)
            } catch is CancellationError {} catch { self.error = error.localizedDescription }
        }
    }
}
