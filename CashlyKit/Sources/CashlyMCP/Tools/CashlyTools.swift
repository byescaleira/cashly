import Foundation

public enum CashlyTools {
    public static let instructions = """
        Cashly é um app de finanças pessoais. Use get_catalog para ver categorias e a moeda, get_summary e list_budgets para entender o mês, list_transactions para conferir o que já existe e run_analysis para números calculados pelo app. Para cadastrar dados, use import_transactions: a pessoa confere e confirma no app antes de gravar. Nunca invente valores; quando não souber a categoria, use a mais próxima existente ou "Outros".
        """

    public static func all(_ context: CashlyContext) -> [any MCPTool] {
        [
            CatalogTool(context: context), SummaryTool(context: context),
            TransactionsTool(context: context),
            BudgetsTool(context: context), AnalysisTool(context: context),
            ImportTool(context: context),
        ]
    }

    public static func server(_ context: CashlyContext, authorizer: MCPAuthorizer? = nil)
        -> MCPServer
    {
        MCPServer(tools: all(context), instructions: instructions, authorizer: authorizer)
    }
}
