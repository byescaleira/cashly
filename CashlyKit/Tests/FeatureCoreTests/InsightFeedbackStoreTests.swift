import CashlyAnalytics
import CashlyDomain
import FeatureCore
import Foundation
import Testing

struct InsightFeedbackStoreTests {
    private let october = YearMonth(year: 2026, month: 10) ?? YearMonth(.now)

    @Test func feedbackIsKeptPerProfileAndErased() {
        let store = InsightFeedbackStore(
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        var feedback = InsightFeedback()
        feedback.markExpected(
            Finding(
                analysisID: "test", topic: .spending, subject: "market", label: "Mercado",
                summary: "", impact: 1, confidence: .high),
            in: october)
        store.save(feedback, for: "owner")
        #expect(store.feedback(for: "owner") == feedback)
        #expect(store.feedback(for: "friend") == InsightFeedback())
        store.erase(["owner"])
        #expect(store.feedback(for: "owner") == InsightFeedback())
    }

    @Test func legacyModelsFolderIsRemoved() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let folder = root.appending(path: "Cashly/Intelligence")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: folder.appending(path: "model.json"))
        LegacyIntelligenceFiles.remove(in: root)
        #expect(!FileManager.default.fileExists(atPath: folder.path))
    }
}
