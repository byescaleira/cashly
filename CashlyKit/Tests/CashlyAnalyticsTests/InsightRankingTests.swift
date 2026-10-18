import CashlyAnalytics
import CashlyDomain
import Foundation
import Testing

struct InsightRankingTests {
    private let october = YearMonth(year: 2026, month: 10) ?? YearMonth(.now)

    private func finding(
        _ subject: String, impact: Int64, confidence: Provenance.Confidence = .high
    ) -> Finding {
        Finding(
            analysisID: "test", topic: .spending, subject: subject, label: subject,
            summary: subject, impact: impact, confidence: confidence)
    }

    @Test func ordersByImpactWeightedByConfidence() {
        let ranked = InsightRanking.rank(
            [
                finding("small", impact: 5_000), finding("big", impact: 20_000, confidence: .low),
                finding("sure", impact: 10_000, confidence: .certain),
            ], in: october)
        #expect(ranked.map(\.subject) == ["sure", "big", "small"])
    }

    @Test func dropsFindingsWithoutImpact() {
        #expect(InsightRanking.rank([finding("none", impact: 0)], in: october).isEmpty)
    }

    @Test func expectedFindingsHideUntilTheNextMonth() throws {
        let market = finding("market", impact: 10_000)
        var feedback = InsightFeedback()
        feedback.markExpected(market, in: october)
        #expect(InsightRanking.rank([market], feedback: feedback, in: october).isEmpty)
        let november = try #require(YearMonth(year: 2026, month: 11))
        #expect(InsightRanking.rank([market], feedback: feedback, in: november) == [market])
    }

    @Test func markingExpectedForgetsPastMonths() throws {
        let market = finding("market", impact: 10_000)
        let november = try #require(YearMonth(year: 2026, month: 11))
        var feedback = InsightFeedback()
        feedback.markExpected(market, in: october)
        feedback.markExpected(finding("fuel", impact: 1), in: november)
        #expect(feedback.expected == ["202611|test|fuel"])
    }
}
