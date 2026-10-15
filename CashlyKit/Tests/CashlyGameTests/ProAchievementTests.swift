import CashlyDomain
import Testing

@testable import CashlyGame

struct ProAchievementTests {
    @Test func proMonthsUnlockTheProGroupInOrder() {
        var fixture = GameFixture(today: 5)
        #expect(fixture.achievement(.proMonth1)?.isUnlocked == false)
        for month in 1...6 {
            fixture.event(.proMonth, day: 1, value: "pro-month-\(month)", count: month)
        }
        #expect(fixture.achievement(.proMonth1)?.isUnlocked == true)
        #expect(fixture.achievement(.proMonth6)?.isUnlocked == true)
        #expect(fixture.achievement(.proYear1)?.value == 6)
        #expect(fixture.achievement(.proYear1)?.isUnlocked == false)
        #expect(Achievement.proYear2.group == .pro)
        #expect(Achievement.proYear2.tier == .gold)
    }
}
