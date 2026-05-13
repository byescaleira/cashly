//
//  InMemoryTransactionDictation.swift
//  CashlyKit
//
//  Test stub: always returns the same canned draft. Lets feature
//  tests exercise the dictation → form flow without parsing.
//

import Foundation
import CashlyDomain

public actor InMemoryTransactionDictation: TransactionDictationUseCase {
    public private(set) var utterances: [String] = []
    private var nextDraft: TransactionDraft

    public init(draft: TransactionDraft = TransactionDraft()) {
        self.nextDraft = draft
    }

    public func setDraft(_ draft: TransactionDraft) {
        self.nextDraft = draft
    }

    public func parse(_ utterance: String) async -> TransactionDraft {
        utterances.append(utterance)
        return nextDraft
    }
}
