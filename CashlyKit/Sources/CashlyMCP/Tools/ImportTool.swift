import CashlyDomain
import Foundation

struct ImportTool: MCPTool {
    let context: CashlyContext
    let name = "import_transactions"
    let description = """
        Envia transações para o Cashly. Nada é gravado direto: o app mostra uma tela de conferência com totais, categorias novas e problemas, e a pessoa confirma. Categorias e tags que não existem são criadas. Valores sempre positivos; use kind para entrada ou saída. Envie até 2.000 itens por chamada.
        """
    let inputSchema = Schema.object(
        [
            "source": Schema.string(
                "De onde vieram os dados, por exemplo \"Extrato Nubank outubro\"."),
            "transactions": [
                "type": "array",
                "items": Schema.object(
                    [
                        "date": Schema.string("Data AAAA-MM-DD."),
                        "description": Schema.string(
                            "Descrição curta e legível, sem códigos do banco."),
                        "amount": Schema.number(
                            "Valor positivo, com centavos. Em compra parcelada, o total da compra."),
                        "kind": ["type": "string", "enum": ["expense", "income"]],
                        "category": Schema.string(
                            "Nome da categoria. Prefira as existentes em get_catalog."),
                        "status": ["type": "string", "enum": ["paid", "to_pay", "to_receive"]],
                        "installments": Schema.integer(
                            "Número de parcelas, 1 a 120. Padrão 1. O app divide o total e lança uma parcela por mês a partir de date."
                        ),
                        "tags": ["type": "array", "items": ["type": "string"]],
                    ], required: ["date", "description", "amount", "kind", "category"]),
            ],
        ], required: ["transactions"])

    func call(_ arguments: JSONValue) async throws -> String {
        guard let items = arguments["transactions"]?.array, !items.isEmpty else {
            throw MCPToolError("Envie ao menos uma transação em transactions.")
        }
        guard items.count <= 2000 else {
            throw MCPToolError("Envie até 2.000 transações por chamada.")
        }
        _ = try await context.workspace()
        var rows: [SpreadsheetRow] = []
        var issues: [SpreadsheetIssue] = []
        for (offset, item) in items.enumerated() {
            do { rows.append(try Self.row(item, line: offset + 1)) } catch let error as MCPToolError
            {
                issues.append(SpreadsheetIssue(line: offset + 1, message: error.message))
            }
        }
        let preview = SpreadsheetPreview(rows: rows, issues: issues)
        let source = arguments["source"]?.string ?? "Claude Code"
        let skipped =
            issues.isEmpty
            ? ""
            : " \(issues.count) itens inválidos ficaram de fora: "
                + issues.prefix(10).map { "#\($0.line) \($0.message)" }.joined(separator: "; ")
        guard !rows.isEmpty else { throw MCPToolError("Nenhuma transação válida.\(skipped)") }
        switch await context.importer.requestImport(preview, source: source) {
        case .imported(let count): return "Importadas \(count) transações.\(skipped)"
        case .declined: return "A pessoa recusou a importação no app.\(skipped)"
        case .waiting:
            return
                "A conferência está aberta no Cashly e ainda não foi confirmada. Peça para a pessoa revisar no app.\(skipped)"
        case .locked:
            return
                "Registrar transações exige o Cashly Pro. Peça para a pessoa assinar no app, em Ajustes › Cashly Pro."
        }
    }

    static func row(_ item: JSONValue, line: Int) throws -> SpreadsheetRow {
        guard let dateText = item["date"]?.string, let date = date(dateText) else {
            throw MCPToolError("data inválida")
        }
        guard let summary = item["description"]?.string?.trimmingCharacters(in: .whitespaces),
            summary.count >= 2
        else { throw MCPToolError("descrição vazia") }
        guard let amount = item["amount"]?.number, amount > 0, amount < 1e12 else {
            throw MCPToolError("valor deve ser positivo")
        }
        let kind: TransactionKind = item["kind"]?.string == "income" ? .income : .expense
        let status: TransactionStatus =
            switch item["status"]?.string {
            case "to_pay": .pendingToPay
            case "to_receive": .pendingToReceive
            default: .settled
            }
        let installments = Int(item["installments"]?.number ?? 1)
        guard (1...120).contains(installments) else {
            throw MCPToolError("parcelas fora de 1 a 120")
        }
        let category = item["category"]?.string?.trimmingCharacters(in: .whitespaces) ?? ""
        return SpreadsheetRow(
            line: line, date: date, summary: summary,
            category: category.isEmpty ? "Outros" : category,
            kind: kind, status: status, money: Money(minorUnits: Int64((amount * 100).rounded())),
            installments: installments, tags: item["tags"]?.array?.compactMap(\.string) ?? [])
    }

    private static func date(_ text: String) -> Date? {
        let parts = text.prefix(10).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)
        guard let date = CashlyCalendar.current.date(from: components),
            CashlyCalendar.current.component(.day, from: date) == parts[2]
        else { return nil }
        return date
    }
}
