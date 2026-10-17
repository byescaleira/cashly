import CashlyAnalyticsAI
import CashlyData
import CashlyDomain
import FeatureCore
import FeatureDashboard
import Foundation
import Testing

@MainActor
struct SummaryModelTests {
    private let owner = User(id: "owner", name: "Perfil")
    private let friend = User(id: "friend", name: "Amigo")

    private func session() async throws -> SessionModel {
        try await InsightsFixture.session(owner: owner, friend: friend)
    }

    @Test func summaryShowsCheckedSentencesUnderTheirSections() async throws {
        let insights = InsightsModel(
            session: try await session(),
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        let calls = Counter()
        let summary = SummaryModel { facts, _, _ in
            await calls.increment()
            let names = facts.prefix(2).map(\.subject)
            return NarrationCheck.validate(
                headline: "Um mês acima do normal.",
                items: [(1, "\(names[0]) subiu."), (2, "\(names[1]) também.")], facts: facts
            ).map { .success($0) } ?? .failure(.rejected)
        }
        await summary.load(from: insights, isPro: true)
        let result = try #require(summary.summary)
        #expect(result.lines.count == 2)
        #expect(result.lines.allSatisfy { !$0.section.isEmpty })
        #expect(Set(result.lines.map(\.id)).count == result.lines.count)
        await summary.load(from: insights, isPro: true)
        #expect(await calls.value == 1)
        let line = try #require(
            result.lines.first { line in insights.unusual.contains { $0.id == line.id } })
        let item = try #require(insights.unusual.first { $0.id == line.id })
        insights.markExpected(item)
        #expect(summary.summary?.lines.contains { $0.id == line.id } != true)
    }

    @Test func summaryNeedsProTheFlagAndAWorkingModel() async throws {
        let insights = InsightsModel(
            session: try await session(),
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        let calls = Counter()
        let flags = FeatureFlags(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        let summary = SummaryModel(flags: flags) { _, _, _ in
            await calls.increment()
            return .failure(.unavailable)
        }
        await summary.load(from: insights, isPro: false)
        flags.override(.summary, false)
        await summary.load(from: insights, isPro: true)
        #expect(await calls.value == 0)
        flags.override(.summary, true)
        await summary.load(from: insights, isPro: true)
        await summary.load(from: insights, isPro: true)
        #expect(await calls.value == 2)
        #expect(summary.summary == nil)
    }

    @Test func aRejectedSummaryIsNotAskedAgainForTheSameFacts() async throws {
        let insights = InsightsModel(
            session: try await session(),
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        let calls = Counter()
        let summary = SummaryModel { _, _, _ in
            await calls.increment()
            return .failure(.rejected)
        }
        await summary.load(from: insights, isPro: true)
        await summary.load(from: insights, isPro: true)
        #expect(await calls.value == 1)
        #expect(summary.summary == nil)
    }
}

private actor Counter {
    private(set) var value = 0

    func increment() { value += 1 }
}
