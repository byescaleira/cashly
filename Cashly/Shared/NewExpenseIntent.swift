import AppIntents
import Foundation

struct NewExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "New Expense"
    static let description = IntentDescription("Opens Cashly on a new expense.")
    static let openAppWhenRun = true
    static let isDiscoverable = false
    static let url = URL(string: "cashly://transactions/new")!
    @MainActor static var open: ((URL) -> Void)?

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        Self.open?(Self.url)
        return .result()
    }
}
