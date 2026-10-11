import CashlyDomain
import Foundation

struct TransactionsTool: MCPTool {
    let context: CashlyContext
    let name = "list_transactions"
    let description =
        "Lista transações, mais recentes primeiro. Filtre por mês, categoria ou texto da descrição. Use para conferir o que já existe e evitar duplicatas antes de importar."
    let inputSchema = Schema.object([
        "month": Schema.string("Mês AAAA-MM. Omita para todos os períodos."),
        "category": Schema.string("Nome da categoria."),
        "text": Schema.string("Trecho da descrição."),
        "limit": Schema.integer("Máximo de itens, até 200. Padrão 50."),
    ])

    private struct Item: Encodable {
        let date: String
        let description: String
        let category: String
        let kind: String
        let status: String
        let amount: Double
        let installments: Int
    }

    func call(_ arguments: JSONValue) async throws -> String {
        let (repositories, _) = try await context.workspace()
        let month =
            arguments["month"]?.string.map { _ in try? context.month(arguments["month"]) } ?? nil
        var categoryIDs: Set<String> = []
        if let name = arguments["category"]?.string {
            let catalog = try await repositories.dashboard.snapshot(month: nil)
            let matches = catalog.categories.filter {
                SpreadsheetParser.key($0.name) == SpreadsheetParser.key(name)
            }
            guard !matches.isEmpty else { throw MCPToolError("Categoria \"\(name)\" não existe.") }
            categoryIDs = Set(matches.map(\.id))
        }
        let limit = min(max(Int(arguments["limit"]?.number ?? 50), 1), 200)
        let query = TransactionQuery(
            month: month, categoryIDs: categoryIDs, text: arguments["text"]?.string ?? "")
        let page = try await repositories.dashboard.page(query: query, after: nil, limit: limit)
        return try Schema.encode(
            page.items.map {
                Item(
                    date: Amount.day($0.date), description: $0.summary, category: $0.category.name,
                    kind: $0.kind == .income ? "income" : "expense", status: Self.status($0.status),
                    amount: $0.money.doubleValue, installments: $0.installmentCount)
            })
    }

    static func status(_ status: TransactionStatus) -> String {
        switch status {
        case .settled: "paid"
        case .pendingToPay: "to_pay"
        case .pendingToReceive: "to_receive"
        case .canceled: "canceled"
        }
    }
}
