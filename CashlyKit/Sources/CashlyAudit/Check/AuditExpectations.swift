enum AuditExpectations {
    static func migration(_ report: MigrationReport) -> [Expectation] {
        let owner = report.users.first { $0.id == "owner" }
        let record = report.records.first
        return MigrationReport.entities.map {
            Expectation(
                "migration.count.\($0)", expected: 1 + ($0 == "users" ? 1 : 0),
                actual: report.counts[$0, default: 0])
        } + [
            Expectation(
                "migration.owner.transactions", expected: 1, actual: owner?.transactions ?? -1),
            Expectation("migration.owner.loaded", expected: 1, actual: owner?.loaded ?? -1),
            Expectation("migration.owner.pending", expected: 0, actual: owner?.pending ?? -1),
            Expectation(
                "migration.owner.expensesMinor", expected: 5001, actual: owner?.ownerMinor ?? -1),
            Expectation(
                "migration.owner.budgetMinor", expected: 10001, actual: owner?.budgetMinor ?? -1),
            Expectation(
                "migration.record.sharesMinor", expected: 10001, actual: record?.sharesMinor ?? -1),
            Expectation(
                "migration.record.installmentsMinor", expected: 5001,
                actual: record?.ownerInstallmentsMinor ?? -1),
            Expectation("migration.record.tags", expected: ["tag"], actual: record?.tagIDs ?? []),
        ]
    }

    static func sample(_ report: SampleReport) -> [Expectation] {
        [
            Expectation("sample.users", expected: 5, actual: report.users),
            Expectation("sample.transactions", expected: 10, actual: report.transactions),
        ]
    }

    static func benchmark(_ report: BenchmarkReport) -> [Expectation] {
        [
            Expectation("benchmark.firstPage", expected: 50, actual: report.firstPageItems),
            Expectation("benchmark.total", expected: report.count / 2, actual: report.total),
            Expectation(
                "benchmark.totalMinor",
                expected: Int64(report.count / 2) * BenchmarkFixture.transactionMinor,
                actual: report.totalMinor),
            Expectation("benchmark.detail", expected: "00000000", actual: report.detailID),
            Expectation("benchmark.nextPage", expected: 50, actual: report.nextPageItems),
            Expectation("benchmark.overlaps", expected: 0, actual: report.overlaps),
            Expectation("benchmark.isolation", expected: true, actual: report.isIsolated),
            Expectation("benchmark.conflictsBefore", expected: 1, actual: report.conflictsBefore),
            Expectation("benchmark.conflictsAfter", expected: 0, actual: report.conflictsAfter),
            Expectation("benchmark.archivedBudgets", expected: 1, actual: report.archivedBudgets),
            Expectation(
                "benchmark.budgetMinor", expected: BenchmarkFixture.budgetMinor,
                actual: report.budgetMinor),
        ]
    }
}
