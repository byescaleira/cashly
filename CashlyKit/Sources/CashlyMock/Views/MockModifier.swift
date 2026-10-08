import CashlyData
import CashlyDomain
import CashlyPresentation
import SwiftUI

struct MockModifier: ViewModifier {
    var includeSampleData = true
    @State private var session: CashlySession?
    @State private var error: String?
    func body(content: Content) -> some View {
        Group {
            if let session {
                content.environment(session).environment(session.main).environment(
                    session.navigation
                )
                .environment(session.intelligence)
                .environment(\.user, session.main.user)
                .task {
                    await session.main.load()
                    await session.intelligence.loadModels(
                        user: session.main.user, revision: session.main.datasetRevision)
                }
            } else if let error {
                Text(error)
            } else {
                ProgressView()
            }
        }.task {
            guard session == nil else { return }
            do {
                let database = try await SampleDatabase.make(seeded: includeSampleData)
                try Task.checkCancellation()
                let directory = FileManager.default.temporaryDirectory.appending(
                    path: UUID().uuidString)
                session = CashlySession(
                    provider: database,
                    intelligence: LocalIntelligenceService(directory: directory),
                    persistSelection: false)
            } catch is CancellationError {} catch { self.error = error.localizedDescription }
        }
    }
}
