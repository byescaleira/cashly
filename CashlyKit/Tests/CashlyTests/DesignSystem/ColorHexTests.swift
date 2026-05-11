//
//  ColorHexTests.swift
//  CashlyKit
//

import Testing
import SwiftUI
@testable import CashlyDesignSystem

@Suite("Color(hex:)", .tags(.unit, .ui, .local))
struct ColorHexTests {
    @Test("nil hex returns .clear")
    func nilHex() {
        let c = Color(hex: nil)
        #expect(c == .clear)
    }

    @Test("empty string returns .clear")
    func emptyHex() {
        let c = Color(hex: "")
        #expect(c == .clear)
    }

    @Test("malformed length returns .clear")
    func malformedHex() {
        #expect(Color(hex: "#FFF") == .clear)
        #expect(Color(hex: "##FFFF00") == .clear)
        #expect(Color(hex: "zzzzzz") == .clear)
    }

    @Test("6-digit hex with leading hash parses")
    func sixDigitWithHash() {
        let c = Color(hex: "#FF0000")
        #expect(c != .clear)
    }

    @Test("6-digit hex without leading hash parses")
    func sixDigitNoHash() {
        let c = Color(hex: "00FF00")
        #expect(c != .clear)
    }

    @Test("8-digit RGBA hex parses")
    func eightDigitRGBA() {
        let c = Color(hex: "#FF000080")
        #expect(c != .clear)
    }

    @Test("whitespace is trimmed before parsing")
    func whitespaceTrimmed() {
        let c = Color(hex: "  #112233  \n")
        #expect(c != .clear)
    }
}
