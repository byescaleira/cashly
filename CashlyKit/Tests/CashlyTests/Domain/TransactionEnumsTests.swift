//
//  TransactionEnumsTests.swift
//  CashlyKit
//
//  Pure-function tests for TransactionStatus and TransactionSplitMode.
//

import Testing
import CashlyDomain

@Suite("Transaction enums", .tags(.unit, .data, .local))
struct TransactionEnumsTests {

    // MARK: - TransactionStatus

    @Test("TransactionStatus.reverse swaps pending pairs")
    func reverseSwapsPendingPairs() {
        #expect(TransactionStatus.pendingToReceive.reverse == .pendingToPay)
        #expect(TransactionStatus.pendingToPay.reverse == .pendingToReceive)
    }

    @Test("TransactionStatus.reverse is identity for settled / canceled")
    func reverseIsIdentityForTerminal() {
        #expect(TransactionStatus.settled.reverse == .settled)
        #expect(TransactionStatus.canceled.reverse == .canceled)
    }

    @Test("TransactionStatus.id matches rawValue")
    func statusId() {
        for status in TransactionStatus.allCases {
            #expect(status.id == status.rawValue)
        }
    }

    @Test("TransactionStatus.summary + icon cover every case")
    func statusUserFacingStrings() {
        for status in TransactionStatus.allCases {
            #expect(!status.summary.isEmpty)
            #expect(!status.icon.isEmpty)
        }
    }

    // MARK: - TransactionSplitMode

    @Test("SplitMode.value(.equal) divides amount by splitValue when > 0")
    func splitModeEqualDivides() {
        let value = TransactionSplitMode.equal.value(splitValue: 4, amount: 100)
        #expect(value == 25)
    }

    @Test("SplitMode.value(.equal) returns nil for splitValue <= 0")
    func splitModeEqualGuardsZero() {
        #expect(TransactionSplitMode.equal.value(splitValue: 0, amount: 100) == nil)
        #expect(TransactionSplitMode.equal.value(splitValue: -1, amount: 100) == nil)
    }

    @Test("SplitMode.value(.fixedAmount) passes through splitValue")
    func splitModeFixedPassthrough() {
        #expect(TransactionSplitMode.fixedAmount.value(splitValue: 17.5, amount: 100) == 17.5)
    }

    @Test("SplitMode.value(.percentage) multiplies amount by splitValue")
    func splitModePercentage() {
        #expect(TransactionSplitMode.percentage.value(splitValue: 0.3, amount: 100) == 30)
    }

    @Test("SplitMode.value(.payerBased) returns zero")
    func splitModePayerBased() {
        #expect(TransactionSplitMode.payerBased.value(splitValue: 999, amount: 100) == 0)
    }

    @Test("SplitMode.value with nil splitValue returns nil")
    func splitModeNilSplitValue() {
        for mode in TransactionSplitMode.allCases {
            #expect(mode.value(splitValue: nil, amount: 100) == nil, "mode \(mode) leaked")
        }
    }

    @Test("SplitMode.id matches rawValue")
    func splitModeId() {
        for mode in TransactionSplitMode.allCases {
            #expect(mode.id == mode.rawValue)
        }
    }

    @Test("SplitMode.summary + description cover every case")
    func splitModeUserFacing() {
        for mode in TransactionSplitMode.allCases {
            #expect(!mode.summary.isEmpty)
            #expect(!mode.description.isEmpty)
        }
    }
}
