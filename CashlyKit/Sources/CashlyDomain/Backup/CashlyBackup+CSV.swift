import Foundation

extension CashlyBackup {
    public var transactionsCSV: String {
        let users = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0.name) })
        let categories = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let tags = Dictionary(uniqueKeysWithValues: tags.map { ($0.id, $0.name) })
        let header = [
            "Data", "Usuário", "Descrição", "Categoria", "Tipo", "Situação", "Valor", "Moeda",
            "Parcelas", "Tags",
        ]
        let rows = transactions.sorted { ($0.date, $0.id) < ($1.date, $1.id) }.map { record in
            let category = categories[record.categoryID]
            return [
                record.date.formatted(
                    Date.ISO8601FormatStyle(timeZone: .current).year().month().day()),
                category.flatMap { users[$0.userID] } ?? "",
                record.summary,
                category?.name ?? "",
                TransactionKind(rawValue: record.kind) == .income ? "Entrada" : "Saída",
                Self.status(record.status),
                Self.amount(record.amount),
                currency,
                String(max(record.paymentsPlan ?? 1, 1)),
                record.tagIDs.compactMap { tags[$0] }.sorted().joined(separator: ", "),
            ]
        }
        return ([header] + rows).map { $0.map(Self.field).joined(separator: ";") }
            .joined(separator: "\r\n") + "\r\n"
    }

    private static func amount(_ minorUnits: Int64) -> String {
        let sign = minorUnits < 0 ? "-" : ""
        let value = minorUnits.magnitude
        let cents = String(value % 100)
        return sign + String(value / 100) + "," + String(repeating: "0", count: 2 - cents.count)
            + cents
    }

    private static func status(_ rawValue: Int) -> String {
        switch TransactionStatus(rawValue: rawValue) {
        case .pendingToPay: "A pagar"
        case .pendingToReceive: "A receber"
        case .canceled: "Cancelada"
        default: "Paga"
        }
    }

    private static func field(_ value: String) -> String {
        guard value.contains(where: { ";\"\n\r".contains($0) }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
