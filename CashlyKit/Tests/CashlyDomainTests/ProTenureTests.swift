import CashlyDomain
import Foundation
import Testing

struct ProTenureTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func period(from day: Double, days: Double) -> DateInterval {
        DateInterval(start: start.addingTimeInterval(day * 86_400), duration: days * 86_400)
    }

    @Test func overlappingPlansCountOnce() {
        #expect(ProTenure.months(of: [period(from: 0, days: 40), period(from: 20, days: 40)]) == 2)
    }

    @Test func breaksBetweenPlansStillAddUp() {
        #expect(
            ProTenure.months(of: [period(from: 0, days: 20), period(from: 100, days: 25)]) == 1)
        #expect(ProTenure.months(of: [period(from: 0, days: 7)]) == 0)
        #expect(ProTenure.months(of: []) == 0)
    }

    @Test func containedAndTouchingPeriodsMerge() {
        let contained = [period(from: 0, days: 90), period(from: 10, days: 20)]
        #expect(ProTenure.months(of: contained) == 3)
        #expect(ProTenure.months(of: [period(from: 0, days: 30), period(from: 30, days: 30)]) == 2)
    }
}
