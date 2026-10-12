import CashlyDomain
import Foundation
import Testing

struct BackupCSVTests {
    @Test func transactionsBecomeSemicolonRows() throws {
        let owner = User(id: "o", name: "Ana", photo: "1")
        let category = Category(
            id: "c", user: owner, name: "Mercado", color: "0099FF", icon: "cart")
        let tag = Tag(id: "t", user: owner, name: "Casa", color: "FF9900", icon: "house")
        let date = try #require(
            CashlyCalendar.current.date(
                from: DateComponents(year: 2026, month: 3, day: 5, hour: 12)))
        let first = Transaction(
            id: "a", participants: [], category: category, money: Money(minorUnits: 123_405),
            date: date, summary: "Feira; \"semana\"", status: .pendingToPay, splitMode: nil,
            splitValue: nil, paymentsPlan: 3, tagIDs: ["t"])
        let second = Transaction(
            id: "b", participants: [], category: category, money: Money(minorUnits: 7),
            date: date.addingTimeInterval(60), summary: "Salário", status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: nil, kind: .income)
        let backup = CashlyBackup(
            users: [owner], categories: [category], tags: [tag], budgets: [],
            transactions: [second, first])
        let lines = backup.transactionsCSV.components(separatedBy: "\r\n")
        #expect(
            lines[0]
                == "Date;User;Description;Category;Type;Status;Amount;Currency;Installments;Tags")
        #expect(
            lines[1]
                == "2026-03-05;Ana;\"Feira; \"\"semana\"\"\";Mercado;Expense;To pay;\(SpreadsheetTerm.amount(123_405));\(backup.currency);3;Casa"
        )
        #expect(
            lines[2]
                == "2026-03-05;Ana;Salário;Mercado;Income;Paid;\(SpreadsheetTerm.amount(7));\(backup.currency);1;"
        )
        #expect(lines.count == 4)
    }
}
