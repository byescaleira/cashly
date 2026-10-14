import CashlyData
import CashlyDomain
import FeatureCore
import Testing

@testable import FeatureSettings

@MainActor
struct GuidesModelTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")

    private func model() async throws -> (GuidesModel, SessionModel) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        return (GuidesModel(session: session), session)
    }

    @Test func nothingDoneSuggestsTheFirstGuide() async throws {
        let (guides, _) = try await model()
        await guides.load()
        #expect(guides.doneCount == 0)
        #expect(guides.fraction == 0)
        #expect(guides.next == .tour)
        #expect(!guides.isComplete)
        #expect(guides.remainingMinutes == Guide.allCases.reduce(0) { $0 + $1.minutes })
    }

    @Test func completedGuidesCountOnceAndMoveTheSuggestion() async throws {
        let (guides, session) = try await model()
        await session.record(.guideCompleted, value: Guide.tour.rawValue)
        await session.record(.guideCompleted, value: Guide.tour.rawValue)
        await session.record(.guideCompleted, value: Guide.recording.rawValue)
        await session.record(.guideCompleted, value: "removed")
        await guides.load()
        #expect(guides.doneCount == 2)
        #expect(guides.isDone(.tour))
        #expect(guides.next == .sharing)
        #expect(guides.doneCount(in: .recording) == 1)
        #expect(guides.doneCount(in: .start) == 1)
    }

    @Test func everyGuideDoneIsComplete() async throws {
        let (guides, session) = try await model()
        for guide in Guide.allCases {
            await session.record(.guideCompleted, value: guide.rawValue)
        }
        await guides.load()
        #expect(guides.isComplete)
        #expect(guides.next == nil)
        #expect(guides.remainingMinutes == 0)
    }

    @Test func everyCategoryHasGuidesAndEveryGuideOneCategory() {
        for category in GuideCategory.allCases {
            #expect(!category.guides.isEmpty)
        }
        let total = GuideCategory.allCases.reduce(0) { $0 + $1.guides.count }
        #expect(total == Guide.allCases.count)
    }
}
