import CashlyData
import CashlyDomain
import CashlyPresentation
import Foundation
import SwiftUI

struct MockModifier: ViewModifier {
    var includeSampleData = true
    @State private var window: CashlyWindow?
    @State private var error: String?

    func body(content: Content) -> some View {
        Group {
            if let window {
                content.cashlyWindow(window)
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
                window = CashlyWindow(
                    provider: database,
                    intelligence: LocalIntelligenceService(directory: directory),
                    preference: .disabled)
            } catch is CancellationError {} catch { self.error = error.localizedDescription }
        }
    }
}
