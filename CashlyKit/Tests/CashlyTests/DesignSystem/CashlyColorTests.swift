//
//  CashlyColorTests.swift
//  CashlyKit
//

import Testing
import SwiftUI
import CashlyDesignSystem

@Suite("CashlyColor.resolved", .tags(.unit, .ui, .local))
struct CashlyColorTests {
    @Test("primary resolves to accentColor")
    func primary() {
        #expect(CashlyColor.primary.resolved == .accentColor)
    }

    @Test("text resolves to .primary")
    func text() {
        #expect(CashlyColor.text.resolved == .primary)
    }

    @Test("textSecondary resolves to .secondary")
    func textSecondary() {
        #expect(CashlyColor.textSecondary.resolved == .secondary)
    }

    @Test("info / success / warning / error map to expected named colors")
    func semanticTokens() {
        #expect(CashlyColor.info.resolved == .blue)
        #expect(CashlyColor.success.resolved == .green)
        #expect(CashlyColor.warning.resolved == .orange)
        #expect(CashlyColor.error.resolved == .red)
    }

    @Test("primitive tokens pass through")
    func primitives() {
        #expect(CashlyColor.white.resolved == .white)
        #expect(CashlyColor.clear.resolved == .clear)
        #expect(CashlyColor.gray.resolved == .gray)
        #expect(CashlyColor.secondary.resolved == .secondary)
        #expect(CashlyColor.yellow.resolved == .yellow)
    }

    @Test("color(nil) resolves to .clear")
    func colorNilFallsBack() {
        #expect(CashlyColor.color(nil).resolved == .clear)
    }

    @Test("color(c) passes the wrapped Color through")
    func colorWraps() {
        let purple = Color.purple
        #expect(CashlyColor.color(purple).resolved == purple)
    }

    @Test("hex(nil) resolves to .clear")
    func hexNilFallsBack() {
        #expect(CashlyColor.hex(nil).resolved == .clear)
    }

    @Test("hex with malformed string falls back to .clear")
    func hexMalformed() {
        #expect(CashlyColor.hex("not-a-color").resolved == .clear)
    }
}
