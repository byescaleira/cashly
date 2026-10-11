import CashlyDomain
import Testing

struct BudgetHealthScaleTests {
    @Test func levelLimitsMatchTheScore() {
        #expect(abs(BudgetHealth.Level.healthy.maximumUsage - 1.0) < 0.01)
        #expect(abs(BudgetHealth.Level.critical.maximumUsage - 2.0) < 0.001)
        for level in BudgetHealth.Level.allCases {
            let health = BudgetHealth(
                usage: BudgetUsage(spent: level.maximumUsage * 100 - 0.01, budgeted: 100))
            #expect(health.score >= level.scores.lowerBound)
        }
    }
}
