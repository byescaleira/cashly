import CashlyData
import CashlyDomain
import Foundation

struct BenchmarkReport {
    var count = 0
    var dashboard = Duration.zero
    var firstPageItems = 0
    var total = 0
    var totalMinor: Int64 = 0
    var detail = Duration.zero
    var detailID = ""
    var nextPage = Duration.zero
    var nextPageItems = 0
    var overlaps = 0
    var isIsolated = false
    var conflictsBefore = 0
    var conflictsAfter = 0
    var archivedBudgets = 0
    var budgetMinor: Int64 = 0
    var folder = URL(filePath: "/")

    var lines: [String] {
        [
            "BENCH count=\(count) dashboard=\(dashboard) pageItems=\(firstPageItems) total=\(total) totalMinor=\(totalMinor)",
            "DETAIL elapsed=\(detail) id=\(detailID)",
            "PAGE elapsed=\(nextPage) items=\(nextPageItems) overlaps=\(overlaps)",
            "ISOLATION foreignDetail=\(isIsolated ? "hidden" : "visible")",
            "CONFLICT before=\(conflictsBefore) after=\(conflictsAfter) preservedAliases=\(archivedBudgets) budgetMinor=\(budgetMinor)",
            "BENCH_STORE \(folder.path)",
        ]
    }

    @MainActor static func measure(count: Int) async throws -> BenchmarkReport {
        var report = BenchmarkReport(count: count, folder: try AuditFolder.make("cashly-benchmark"))
        let database = try BenchmarkFixture.create(count: count, in: report.folder)
        let repositories = database.repositories(for: "a")
        let query = TransactionQuery(month: try .audit(202601))
        let clock = ContinuousClock()

        var start = clock.now
        let state = try await repositories.dashboard.load(query: query)
        let firstPage = try await repositories.dashboard.page(query: query, after: nil, limit: 50)
        report.dashboard = start.duration(to: clock.now)
        report.firstPageItems = firstPage.items.count
        report.total = state.overview.transactionCount
        report.totalMinor = state.overview.expensesTotal.minorUnits

        start = clock.now
        report.detailID =
            try await repositories.transactions.transaction(id: "00000000")?.id ?? "nil"
        report.detail = start.duration(to: clock.now)

        start = clock.now
        let nextPage = try await repositories.dashboard.page(
            query: query, after: firstPage.nextCursor, limit: 50)
        report.nextPage = start.duration(to: clock.now)
        report.nextPageItems = nextPage.items.count
        report.overlaps =
            Set(nextPage.items.map(\.id)).intersection(firstPage.items.map(\.id)).count
        report.isIsolated =
            try await database.repositories(for: "b").transactions.transaction(id: "00000000")
            == nil

        try BenchmarkFixture.addConflict(to: database)
        report.conflictsBefore = try await repositories.dashboard.overview(query: query).conflicts
            .count
        try await repositories.budgets.resolveConflict(keeping: "budget-a")
        let after = try await repositories.dashboard.overview(query: query)
        report.conflictsAfter = after.conflicts.count
        report.budgetMinor = after.budgetsTotal.minorUnits
        report.archivedBudgets = try BenchmarkFixture.archivedBudgets(in: database)
        return report
    }
}
