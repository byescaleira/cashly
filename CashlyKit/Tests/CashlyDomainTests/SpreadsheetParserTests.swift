import CashlyDomain
import Foundation
import Testing

struct SpreadsheetParserTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
        return calendar
    }

    @Test func templateIsValid() {
        let preview = SpreadsheetParser.parse(SpreadsheetParser.template, calendar: calendar)
        #expect(preview.issues.isEmpty)
        #expect(preview.rows.count == 3)
        #expect(preview.income.minorUnits == 500_000)
        #expect(preview.expenses.minorUnits == 24_590 + 360_000)
        #expect(preview.rows[2].installments == 10)
        #expect(preview.rows[2].status == .pendingToPay)
        #expect(preview.rows[0].tags == ["Housing"])
    }

    @Test func readsTheExportedFormatAndQuotes() throws {
        let text =
            "Data;Usuário;Descrição;Categoria;Tipo;Situação;Valor;Moeda;Parcelas;Tags\r\n"
            + "2026-01-15;Ana;\"Jantar; com \"\"amigos\"\"\";Lazer;Saída;Paga;120,50;BRL;1;Viagem, Amigos\r\n"
        let preview = SpreadsheetParser.parse(text, calendar: calendar)
        let row = try #require(preview.rows.first)
        #expect(row.summary == "Jantar; com \"amigos\"")
        #expect(row.money.minorUnits == 12_050)
        #expect(row.tags == ["Viagem", "Amigos"])
    }

    @Test func commaSeparatedWithBrazilianDates() {
        let text = "data,descricao,valor,tipo\n05/10/2026,Café,\"R$ 1.234,56\",entrada\n"
        let preview = SpreadsheetParser.parse(text, calendar: calendar)
        #expect(preview.rows.first?.money.minorUnits == 123_456)
        #expect(preview.rows.first?.kind == .income)
        #expect(preview.rows.first?.status == .settled)
        #expect(preview.rows.first?.category == "Other")
        #expect(calendar.component(.month, from: preview.rows.first?.date ?? .distantPast) == 10)
    }

    @Test func invalidLinesBecomeIssuesWithTheLineNumber() {
        let text =
            "Data;Descrição;Valor\n2026-02-30;Aluguel;1500\n2026-03-01;;10\n2026-03-02;Luz;abc\n2026-03-03;Água;80\n"
        let preview = SpreadsheetParser.parse(text, calendar: calendar)
        #expect(preview.rows.count == 1)
        #expect(preview.issues.map(\.line) == [2, 3, 4])
    }

    @Test func missingColumnsAreReported() {
        let preview = SpreadsheetParser.parse("Nome;Preço\nA;1\n", calendar: calendar)
        #expect(preview.rows.isEmpty)
        #expect(preview.issues.first?.line == 1)
    }

    @Test func newNamesIgnoreCaseAndAccents() {
        let preview = SpreadsheetParser.parse(SpreadsheetParser.template, calendar: calendar)
        #expect(preview.newCategories(existing: ["groceries", "TECHNOLOGY"]) == ["Work"])
        #expect(preview.newTags(existing: ["housing"]).isEmpty)
    }
}
