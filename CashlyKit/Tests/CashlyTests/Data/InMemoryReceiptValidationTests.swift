//
//  InMemoryReceiptValidationTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemoryReceiptValidation", .tags(.unit, .data, .local))
struct InMemoryReceiptValidationTests {

    private func payload() -> ReceiptPayload {
        ReceiptPayload(jws: "jws.token.value", bundleId: "com.cashly.app")
    }

    @Test("default stub returns .valid(.pro, nil)")
    func defaultStub() async {
        let svc = InMemoryReceiptValidation()
        let result = await svc.validate(payload())
        #expect(result == .valid(tier: .pro, expiresAt: nil))
    }

    @Test("setResult mutates the next response")
    func mutableStub() async {
        let svc = InMemoryReceiptValidation()
        await svc.setResult(.invalid(reason: "stub"))
        let result = await svc.validate(payload())
        #expect(result == .invalid(reason: "stub"))
    }

    @Test("validate records every request")
    func recordsRequests() async {
        let svc = InMemoryReceiptValidation()
        _ = await svc.validate(payload())
        _ = await svc.validate(payload())
        let recorded = await svc.requests
        #expect(recorded.count == 2)
        #expect(recorded.first?.bundleId == "com.cashly.app")
    }
}
