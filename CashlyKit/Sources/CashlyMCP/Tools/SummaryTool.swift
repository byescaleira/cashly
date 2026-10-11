import CashlyDomain
import Foundation

struct SummaryTool: MCPTool {
    let context: CashlyContext
    let name = "get_summary"
    let description =
        "Resumo de um mês: entradas, saídas, saldo, total planejado em orçamentos, pontuação de saúde (200 a 1.000) e gasto por categoria."
    let inputSchema = Schema.object([
        "month": Schema.string("Mês no formato AAAA-MM. Padrão: mês atual.")
    ])

    private struct Output: Encodable {
        let month: String
        let income: Double
        let expenses: Double
        let net: Double
        let planned: Double
        let transactions: Int
        let score: Int
        let byCategory: [String: Double]
    }

    func call(_ arguments: JSONValue) async throws -> String {
        let month = try context.month(arguments["month"])
        let (repositories, _) = try await context.workspace()
        let overview = try await repositories.dashboard.overview(
            query: TransactionQuery(month: month))
        let catalog = try await repositories.dashboard.snapshot(month: month)
        let names = Dictionary(
            catalog.categories.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let health = BudgetHealth(
            usage: BudgetUsage(
                spent: overview.expensesTotal.doubleValue,
                budgeted: overview.budgetsTotal.doubleValue))
        return try Schema.encode(
            Output(
                month: "\(month.year)-\(String(format: "%02d", month.month))",
                income: overview.incomeTotal.doubleValue,
                expenses: overview.expensesTotal.doubleValue,
                net: overview.netTotal.doubleValue, planned: overview.budgetsTotal.doubleValue,
                transactions: overview.transactionCount, score: health.score,
                byCategory: Dictionary(
                    overview.categoryExpenses.map {
                        (names[$0.key] ?? $0.key, $0.value.doubleValue)
                    },
                    uniquingKeysWith: +)))
    }
}
