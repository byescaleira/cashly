import FeatureCore
import Testing

struct ProShowcaseTests {
    private let showcases: [ProShowcase] = [.home, .data, .claudeCode, .web]

    @Test func everyPitchBelongsToExactlyOneScreen() {
        let listed = showcases.flatMap(\.pitches)
        #expect(listed.count == Set(listed).count)
        #expect(Set(listed) == Set(ProPitch.allCases))
    }

    @Test func homeListsEveryInsightOfTheScreen() {
        #expect(
            ProShowcase.home.pitches == [
                .score, .forecast, .variance, .history, .unusual, .changes, .merchants,
                .smallPurchases, .weekdays, .tags, .recurring, .budgetIdeas, .future,
            ])
        #expect(ProShowcase.data.pitches == [.backups, .imports])
    }
}
