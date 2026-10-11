import CashlyDomain
import Foundation

struct CatalogTool: MCPTool {
    let context: CashlyContext
    let name = "get_catalog"
    let description =
        "Mostra o perfil ativo, a moeda, a data de hoje e as categorias e tags existentes. Chame antes de importar para reaproveitar os nomes de categoria."
    let inputSchema = Schema.object([:])

    private struct Output: Encodable {
        let user: String
        let currency: String
        let today: String
        let categories: [String]
        let tags: [String]
    }

    func call(_ arguments: JSONValue) async throws -> String {
        let (repositories, user) = try await context.workspace()
        let snapshot = try await repositories.dashboard.snapshot(month: nil)
        return try Schema.encode(
            Output(
                user: user.name, currency: Money.currencyCode, today: Amount.day(context.today()),
                categories: snapshot.categories.map(\.name).sorted(),
                tags: snapshot.tags.map(\.name).sorted()))
    }
}
