//
//  DoubleExtensionTests.swift
//  CashlyKit
//
//  Pure-function tests for Double extensions in CashlyUI:
//  currencyColor, percentage, variationMessage, variationColor.
//

import SwiftUI
import Testing
@testable import CashlyUI

@Suite("Double extensions", .tags(.unit, .ui, .local))
struct DoubleExtensionTests {

    // MARK: - currencyColor

    @Test("currencyColor with reference=0: positive → success, negative → error, zero → textSecondary")
    func currencyColorZeroReference() {
        switch Double(10).currencyColor() {
        case .success: break
        default: Issue.record("expected .success for positive")
        }
        switch Double(-5).currencyColor() {
        case .error: break
        default: Issue.record("expected .error for negative")
        }
        switch Double(0).currencyColor() {
        case .textSecondary: break
        default: Issue.record("expected .textSecondary for zero")
        }
    }

    @Test("currencyColor with non-zero reference inverts polarity (over budget = error)")
    func currencyColorNonZeroReference() {
        // Spending 60 against budget 50 → over budget → .error
        switch Double(60).currencyColor(reference: 50) {
        case .error: break
        default: Issue.record("expected .error when self > reference")
        }
        // Spending 30 against budget 50 → under budget → .success
        switch Double(30).currencyColor(reference: 50) {
        case .success: break
        default: Issue.record("expected .success when self < reference")
        }
        // Exactly matches → .warning
        switch Double(50).currencyColor(reference: 50) {
        case .warning: break
        default: Issue.record("expected .warning when self == reference")
        }
    }

    // MARK: - percentage

    @Test("percentage rounds to 0 fraction digits and appends %")
    func percentageFormatting() {
        #expect(Double(0.5).percentage == "50%")
        #expect(Double(0).percentage == "0%")
        #expect(Double(1).percentage == "100%")
        #expect(Double(0.567).percentage == "57%")
    }

    // MARK: - variationMessage

    @Test("variationMessage thresholds")
    func variationMessageThresholds() {
        #expect(Double(0.05).variationMessage == "Just started")
        #expect(Double(0.2).variationMessage == "On track")
        #expect(Double(0.6).variationMessage == "Watch out")
        #expect(Double(0.95).variationMessage == "Almost spent")
        #expect(Double(1.1).variationMessage == "Over budget")
        #expect(Double(1.0).variationMessage == "Over budget") // boundary
    }

    // MARK: - variationColor

    @Test("variationColor thresholds")
    func variationColorThresholds() {
        #expect(Double(0.2).variationColor == .green)
        #expect(Double(0.6).variationColor == .yellow)
        #expect(Double(0.95).variationColor == .orange)
        #expect(Double(1.1).variationColor == .red)
    }
}
