import CashlyDomain
import Testing

struct BudgetHealthTests {
    @Test(arguments: [
        (0.0, BudgetUsage.Stage.justStarted),
        (0.09, .justStarted),
        (0.1, .onTrack),
        (0.49, .onTrack),
        (0.5, .watchOut),
        (0.89, .watchOut),
        (0.9, .almostSpent),
        (0.99, .almostSpent),
        (1.0, .overBudget),
        (3.0, .overBudget),
    ])
    func usageStages(ratio: Double, stage: BudgetUsage.Stage) {
        #expect(BudgetUsage(ratio: ratio).stage == stage)
    }

    @Test func usageTreatsMissingBudgetAsOne() {
        #expect(BudgetUsage(spent: 50, budgeted: 0).ratio == 50)
        #expect(BudgetUsage(spent: 50, budgeted: 200).ratio == 0.25)
        let money = BudgetUsage(spent: Money(minorUnits: 7500), budgeted: Money(minorUnits: 10000))
        #expect(money.ratio == 0.75)
    }

    @Test func warningStartsAtEightyPercent() {
        #expect(!BudgetUsage(ratio: 0.79).isWarning)
        #expect(BudgetUsage(ratio: 0.8).isWarning)
    }

    @Test(arguments: [
        (0.0, 1000),
        (0.85, 1000),
        (1.0, 895),
        (1.5, 547),
        (2.0, 200),
        (10.0, 200),
        (Double.nan, 200),
    ])
    func scoreFollowsUsage(ratio: Double, score: Int) {
        #expect(BudgetHealth(usage: BudgetUsage(ratio: ratio)).score == score)
    }

    @Test(arguments: [
        (1000, BudgetHealth.Level.healthy),
        (895, .healthy),
        (894, .overBudget),
        (700, .overBudget),
        (699, .atRisk),
        (500, .atRisk),
        (499, .critical),
        (200, .critical),
    ])
    func levelsCoverEveryScore(score: Int, level: BudgetHealth.Level) {
        #expect(BudgetHealth.Level.allCases.filter { $0.scores.contains(score) } == [level])
    }

    @Test func progressIsRelativeToLevelRange() {
        #expect(BudgetHealth.Level.healthy.progress(for: 895) == 0)
        #expect(BudgetHealth.Level.healthy.progress(for: 1000) == 1)
        #expect(BudgetHealth.Level.critical.progress(for: 100) == 0)
    }
}
