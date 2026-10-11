import CashlyDomain
import Foundation

struct BudgetsTool: MCPTool {
    let context: CashlyContext
    let name = "list_budgets"
    let description = "Orçamentos de um mês com planejado, gasto, quanto sobra e a situação."
    let inputSchema = Schema.object(["month": Schema.string("Mês AAAA-MM. Padrão: mês atual.")])

    private struct Item: Encodable {
        let category: String
        let planned: Double
        let spent: Double
        let remaining: Double
        let situation: String
    }

    func call(_ arguments: JSONValue) async throws -> String {
        let month = try context.month(arguments["month"])
        let (repositories, _) = try await context.workspace()
        let overview = try await repositories.dashboard.overview(
            query: TransactionQuery(month: month))
        return try Schema.encode(
            overview.budgets.map { budget in
                let planned = budget.money.doubleValue
                let spent = overview.budgetExpenses[budget.id, default: .zero].doubleValue
                let ratio = planned > 0 ? spent / planned : 0
                return Item(
                    category: budget.category.name, planned: planned, spent: spent,
                    remaining: planned - spent,
                    situation: spent <= 0
                        ? "untouched" : ratio > 1 ? "over" : ratio >= 0.8 ? "attention" : "on_track"
                )
            })
    }
}
