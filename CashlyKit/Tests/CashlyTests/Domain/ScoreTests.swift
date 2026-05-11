//
//  ScoreTests.swift
//  CashlyKit
//
//  Pure-function tests for Domain Score and BalanceScore — verify the
//  level cutoffs and the [critical, atRisk, overBudget, healthy] order
//  returned by .scores(for:).
//

import Testing
import CashlyDomain

@Suite("Domain Score", .tags(.unit, .data, .local))
struct ScoreTests {

    @Test("BalanceScore.scores returns the four cutoffs in canonical order")
    func scoresOrder() {
        let score = BalanceScore(score: 800).scores
        #expect(score.count == 4)
        #expect(score.map(\.level) == [.critical, .atRisk, .overBudget, .healthy])
    }

    @Test("critical isEnable when score in [200, 499]")
    func criticalRange() {
        let lo = BalanceScore(score: 200).scores[0]
        let hi = BalanceScore(score: 499).scores[0]
        let above = BalanceScore(score: 500).scores[0]
        #expect(lo.isEnable == true)
        #expect(hi.isEnable == true)
        #expect(above.isEnable == false)
    }

    @Test("atRisk isEnable when score in [500, 699]")
    func atRiskRange() {
        let lo = BalanceScore(score: 500).scores[1]
        let hi = BalanceScore(score: 699).scores[1]
        let above = BalanceScore(score: 700).scores[1]
        #expect(lo.isEnable == true)
        #expect(hi.isEnable == true)
        #expect(above.isEnable == false)
    }

    @Test("overBudget isEnable when score in [700, 894]")
    func overBudgetRange() {
        let lo = BalanceScore(score: 700).scores[2]
        let hi = BalanceScore(score: 894).scores[2]
        let above = BalanceScore(score: 895).scores[2]
        #expect(lo.isEnable == true)
        #expect(hi.isEnable == true)
        #expect(above.isEnable == false)
    }

    @Test("healthy isEnable when score in [895, 1000]")
    func healthyRange() {
        let lo = BalanceScore(score: 895).scores[3]
        let hi = BalanceScore(score: 1000).scores[3]
        let below = BalanceScore(score: 894).scores[3]
        #expect(lo.isEnable == true)
        #expect(hi.isEnable == true)
        #expect(below.isEnable == false)
    }

    @Test("progress is (score - min) / (max - min)")
    func progressLinear() {
        let healthy = BalanceScore(score: 1000).scores[3]
        // min 895, max 1000 → (1000 - 895) / (1000 - 895) = 1
        #expect(healthy.progress == 1)

        let critical = BalanceScore(score: 200).scores[0]
        // min 200, max 499 → (200 - 200) / (499 - 200) = 0
        #expect(critical.progress == 0)
    }

    @Test("each Score has stable id == title")
    func stableId() {
        let score = BalanceScore(score: 500).scores
        #expect(score.map(\.id) == ["Critical", "At Risk", "Over Budget", "Healthy"])
    }
}
