//
//  InMemoryReceiptValidation.swift
//  CashlyKit
//
//  Stub ReceiptValidationUseCase for tests + previews + macOS dev
//  builds. Returns a configurable result for every call without
//  hitting any network.
//

import Foundation
import CashlyDomain

public actor InMemoryReceiptValidation: ReceiptValidationUseCase {
    public private(set) var requests: [ReceiptPayload] = []
    private var nextResult: ReceiptValidationResult

    public init(stub: ReceiptValidationResult = .valid(tier: .pro, expiresAt: nil)) {
        self.nextResult = stub
    }

    public func setResult(_ result: ReceiptValidationResult) {
        self.nextResult = result
    }

    public func validate(_ payload: ReceiptPayload) async -> ReceiptValidationResult {
        requests.append(payload)
        return nextResult
    }
}
