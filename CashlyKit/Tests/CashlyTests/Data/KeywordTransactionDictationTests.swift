//
//  KeywordTransactionDictationTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("KeywordTransactionDictation", .tags(.unit, .data, .local))
struct KeywordTransactionDictationTests {

    @Test("parses amount with dot decimal")
    func dotAmount() async {
        let parser = KeywordTransactionDictation()
        let draft = await parser.parse("Lunch 12.50 at Joe's")
        #expect(draft.amount == 12.5)
        #expect(draft.kind == .expense)
        #expect(draft.summary?.contains("Lunch") == true)
    }

    @Test("parses comma decimal")
    func commaAmount() async {
        let parser = KeywordTransactionDictation()
        let draft = await parser.parse("Almoço R$ 12,50 no restaurante")
        #expect(draft.amount == 12.5)
    }

    @Test("'recebi' classifies as income")
    func incomeMarker() async {
        let parser = KeywordTransactionDictation()
        let draft = await parser.parse("Recebi 100 de freela")
        #expect(draft.kind == .income)
        #expect(draft.amount == 100)
    }

    @Test("'emprestei' classifies as loan")
    func loanMarker() async {
        let parser = KeywordTransactionDictation()
        let draft = await parser.parse("Emprestei 50 pro Bruno")
        #expect(draft.kind == .loan)
    }

    @Test("missing amount keeps draft in needsReview state")
    func missingAmount() async {
        let parser = KeywordTransactionDictation()
        let draft = await parser.parse("almoço com Bruno")
        #expect(draft.amount == nil)
        #expect(draft.needsReview)
    }

    @Test("InMemory stub records every utterance")
    func inMemoryRecords() async {
        let stub = InMemoryTransactionDictation(draft: TransactionDraft(amount: 1, summary: "S", kind: .expense, categoryName: "Food"))
        _ = await stub.parse("a")
        _ = await stub.parse("b")
        let recorded = await stub.utterances
        #expect(recorded == ["a", "b"])
    }
}
