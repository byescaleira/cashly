import CashlyAnalytics
import CashlyDomain
import Foundation

struct AnalysisTool: MCPTool {
    let context: CashlyContext
    let name = "run_analysis"
    let description: String
    let inputSchema: JSONValue

    init(context: CashlyContext) {
        self.context = context
        let ids = context.engine.catalog.map { "\($0.id.rawValue): \($0.detail)" }.joined(
            separator: " ")
        description =
            "Roda as análises do Cashly. Os números vêm de cálculo determinístico e trazem a origem. Disponíveis: \(ids)"
        inputSchema = Schema.object([
            "id": Schema.string("Análise a rodar. Omita para rodar todas.")
        ])
    }

    func call(_ arguments: JSONValue) async throws -> String {
        let (repositories, _) = try await context.workspace()
        let ledger = try await RepositoriesLedgerSource(repositories: repositories).ledger(
            today: context.today())
        if let id = arguments["id"]?.string {
            guard let result = await context.engine.run(AnalysisID(rawValue: id), on: ledger) else {
                throw MCPToolError("A análise \(id) não existe ou não tem dados suficientes.")
            }
            return try Schema.encode(result)
        }
        return try Schema.encode(await context.engine.runAll(on: ledger))
    }
}
