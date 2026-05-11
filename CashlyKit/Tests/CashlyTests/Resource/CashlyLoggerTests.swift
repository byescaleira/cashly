//
//  CashlyLoggerTests.swift
//  CashlyKit
//
//  Sanity tests for the CashlyLogger surface. We can't easily
//  intercept os.Logger output, but we can verify the subsystem
//  constant and that every category logger is reachable.
//

import Testing
import CashlyResource

@Suite("CashlyLogger", .tags(.unit, .data, .local))
struct CashlyLoggerTests {
    @Test("subsystem matches the app bundle id")
    func subsystem() {
        #expect(CashlyLogger.subsystem == "com.cashly.app")
    }

    @Test("every category logger is reachable")
    func categoriesReachable() {
        // Just touching the lazy property ensures init succeeds.
        _ = CashlyLogger.data
        _ = CashlyLogger.domain
        _ = CashlyLogger.presentation
        _ = CashlyLogger.ui
        _ = CashlyLogger.intelligence
        _ = CashlyLogger.app
    }

    @Test("logging through every category does not crash")
    func loggingDoesNotCrash() {
        CashlyLogger.data.info("test")
        CashlyLogger.domain.info("test")
        CashlyLogger.presentation.info("test")
        CashlyLogger.ui.info("test")
        CashlyLogger.intelligence.info("test")
        CashlyLogger.app.info("test")
    }
}
