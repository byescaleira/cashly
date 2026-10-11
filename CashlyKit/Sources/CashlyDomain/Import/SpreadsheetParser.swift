import Foundation

public enum SpreadsheetParser {
    public static let template =
        "Data;Descrição;Categoria;Tipo;Situação;Valor;Parcelas;Tags\r\n"
        + "2026-10-05;Supermercado;Mercado;Saída;Paga;245,90;1;Casa\r\n"
        + "2026-10-05;Salário;Trabalho;Entrada;Paga;5.000,00;1;\r\n"
        + "2026-10-12;Notebook;Tecnologia;Saída;A pagar;3.600,00;10;\r\n"

    private enum Column: CaseIterable {
        case date, summary, category, kind, status, amount, installments, tags

        var names: [String] {
            switch self {
            case .date: ["data"]
            case .summary: ["descricao", "historico"]
            case .category: ["categoria"]
            case .kind: ["tipo"]
            case .status: ["situacao", "status"]
            case .amount: ["valor"]
            case .installments: ["parcelas"]
            case .tags: ["tags", "tag"]
            }
        }
    }

    public static func parse(_ text: String, calendar: Calendar = .current) -> SpreadsheetPreview {
        let separator: Character = text.prefix { $0 != "\n" }.contains(";") ? ";" : ","
        let lines = records(text, separator: separator)
        guard let header = lines.first else {
            return SpreadsheetPreview(
                rows: [], issues: [SpreadsheetIssue(line: 1, message: "O arquivo está vazio.")])
        }
        var index: [Column: Int] = [:]
        for (position, name) in header.enumerated() {
            if let column = Column.allCases.first(where: { $0.names.contains(key(name)) }) {
                index[column] = position
            }
        }
        let missing = [Column.date, .summary, .amount].filter { index[$0] == nil }
        guard missing.isEmpty else {
            return SpreadsheetPreview(
                rows: [],
                issues: [
                    SpreadsheetIssue(
                        line: 1, message: "Faltam as colunas Data, Descrição e Valor no cabeçalho.")
                ])
        }
        var rows: [SpreadsheetRow] = []
        var issues: [SpreadsheetIssue] = []
        for (offset, fields) in lines.dropFirst().enumerated() {
            let line = offset + 2
            guard fields.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
            else { continue }
            func value(_ column: Column) -> String {
                guard let position = index[column], position < fields.count else { return "" }
                return fields[position].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            do {
                rows.append(try row(line: line, value: value, calendar: calendar))
            } catch let error as SpreadsheetIssue {
                issues.append(error)
            } catch {
                issues.append(SpreadsheetIssue(line: line, message: "Linha inválida."))
            }
        }
        return SpreadsheetPreview(rows: rows, issues: issues)
    }

    static func key(_ text: String) -> String {
        text.folding(
            options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pt_BR")
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func row(
        line: Int, value: (Column) -> String, calendar: Calendar
    ) throws -> SpreadsheetRow {
        guard let date = date(value(.date), calendar: calendar) else {
            throw SpreadsheetIssue(
                line: line,
                message: "Data \"\(value(.date))\" não reconhecida. Use 2026-10-05 ou 05/10/2026.")
        }
        let summary = value(.summary)
        guard summary.count >= 2 else {
            throw SpreadsheetIssue(line: line, message: "Descrição vazia.")
        }
        guard let minorUnits = amount(value(.amount)), minorUnits != 0 else {
            throw SpreadsheetIssue(
                line: line, message: "Valor \"\(value(.amount))\" não reconhecido. Use 1.234,56.")
        }
        let kindText = key(value(.kind))
        let kind: TransactionKind =
            kindText.hasPrefix("entrada") || kindText.hasPrefix("receita")
            ? .income
            : kindText.isEmpty && minorUnits > 0 && value(.amount).hasPrefix("+")
                ? .income : .expense
        let installments = Int(value(.installments)) ?? 1
        guard (1...120).contains(installments) else {
            throw SpreadsheetIssue(line: line, message: "Parcelas devem ficar entre 1 e 120.")
        }
        let category = value(.category)
        return SpreadsheetRow(
            line: line, date: date, summary: summary,
            category: category.isEmpty ? "Outros" : category, kind: kind,
            status: status(value(.status), kind: kind), money: Money(minorUnits: abs(minorUnits)),
            installments: installments,
            tags: value(.tags).split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty })
    }

    private static func date(_ text: String, calendar: Calendar) -> Date? {
        let parts = text.split(whereSeparator: { "-/.".contains($0) }).compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        if text.contains("-") && parts[0] > 31 {
            (components.year, components.month, components.day) = (parts[0], parts[1], parts[2])
        } else {
            (components.day, components.month, components.year) = (
                parts[0], parts[1], parts[2] < 100 ? 2000 + parts[2] : parts[2]
            )
        }
        components.hour = 12
        guard let date = calendar.date(from: components),
            calendar.component(.day, from: date) == components.day
        else { return nil }
        return date
    }

    private static func amount(_ text: String) -> Int64? {
        var digits = text.filter { "0123456789,.-".contains($0) }
        let negative = digits.hasPrefix("-")
        digits.removeAll { $0 == "-" }
        if let comma = digits.lastIndex(of: ","), digits[comma...].count <= 3 {
            digits = digits.replacingOccurrences(of: ".", with: "").replacingOccurrences(
                of: ",", with: ".")
        } else {
            digits = digits.replacingOccurrences(of: ",", with: "")
        }
        guard let decimal = Decimal(string: digits, locale: Locale(identifier: "en_US_POSIX"))
        else {
            return nil
        }
        let cents = NSDecimalNumber(decimal: decimal * 100).rounding(accordingToBehavior: nil)
            .int64Value
        return negative ? -cents : cents
    }

    private static func status(_ text: String, kind: TransactionKind) -> TransactionStatus {
        let value = key(text)
        if value.contains("cancel") { return .canceled }
        if value.contains("receber") { return .pendingToReceive }
        if value.contains("pagar") || value.contains("pendente") {
            return kind == .income ? .pendingToReceive : .pendingToPay
        }
        return .settled
    }

    private static func records(_ text: String, separator: Character) -> [[String]] {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var quoted = false
        var iterator = text.makeIterator()
        var pending: Character?
        while let character = pending ?? iterator.next() {
            pending = nil
            if quoted {
                if character == "\"" {
                    let next = iterator.next()
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        quoted = false
                        pending = next
                    }
                } else {
                    field.append(character)
                }
                continue
            }
            switch character {
            case "\"": quoted = true
            case separator:
                record.append(field)
                field = ""
            case "\n", "\r\n":
                record.append(field)
                records.append(record)
                record = []
                field = ""
            case "\r": break
            default: field.append(character)
            }
        }
        if !field.isEmpty || !record.isEmpty {
            record.append(field)
            records.append(record)
        }
        return records
    }
}

extension SpreadsheetIssue: Error {}
