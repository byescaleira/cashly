import FeatureCore
import Testing

struct ProShowcaseTests {
    private let showcases: [ProShowcase] = [.home, .data, .intelligence, .claudeCode]

    @Test func everyPitchBelongsToExactlyOneScreen() {
        let listed = showcases.flatMap(\.pitches)
        #expect(listed.count == Set(listed).count)
        #expect(Set(listed) == Set(ProPitch.allCases))
    }

    @Test func homeListsEveryInsightOfTheScreen() {
        #expect(
            ProShowcase.home.pitches == [
                .score, .forecast, .history, .unusual, .future, .variance, .tags,
            ])
        #expect(ProShowcase.data.pitches == [.backups, .imports])
    }
}
