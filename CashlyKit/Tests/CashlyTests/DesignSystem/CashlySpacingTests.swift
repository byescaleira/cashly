//
//  CashlySpacingTests.swift
//  CashlyKit
//

import Testing
import CoreGraphics
import CashlyDesignSystem

@Suite("CashlySpacing.rawValue", .tags(.unit, .ui, .local))
struct CashlySpacingTests {
    @Test("zero is 0")
    func zero() { #expect(CashlySpacing.zero.rawValue == 0) }

    @Test("extraSmall is 4")
    func extraSmall() { #expect(CashlySpacing.extraSmall.rawValue == 4) }

    @Test("small is 8")
    func small() { #expect(CashlySpacing.small.rawValue == 8) }

    @Test("medium is 16")
    func medium() { #expect(CashlySpacing.medium.rawValue == 16) }

    @Test("large is 24")
    func large() { #expect(CashlySpacing.large.rawValue == 24) }

    @Test("extraLarge is 32")
    func extraLarge() { #expect(CashlySpacing.extraLarge.rawValue == 32) }

    @Test("ultraLarge is 48")
    func ultraLarge() { #expect(CashlySpacing.ultraLarge.rawValue == 48) }

    @Test("section is 64")
    func section() { #expect(CashlySpacing.section.rawValue == 64) }

    @Test("negative(.small) inverts sign")
    func negativeSmall() {
        #expect(CashlySpacing.negative(.small).rawValue == -8)
    }

    @Test("negative(.medium) inverts sign")
    func negativeMedium() {
        #expect(CashlySpacing.negative(.medium).rawValue == -16)
    }

    @Test("custom passes through")
    func custom() {
        #expect(CashlySpacing.custom(13.5).rawValue == 13.5)
    }

    @Test("negative(.custom(...)) inverts custom")
    func negativeCustom() {
        #expect(CashlySpacing.negative(.custom(20)).rawValue == -20)
    }
}
