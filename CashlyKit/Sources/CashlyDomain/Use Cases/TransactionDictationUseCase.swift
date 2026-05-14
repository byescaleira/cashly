//
//  TransactionDictationUseCase.swift
//  CashlyKit
//
//  Parses a natural-language utterance into a Transaction draft.
//  Production impl (deferred to J9) talks to Foundation Models /
//  Apple Intelligence; in-memory impl (J8) ships a keyword matcher
//  so the rest of the dictation flow can be tested end-to-end
//  without on-device LLM access.
//
//  Fields that the parser can't infer return nil; the caller
//  flips `needsReview` so the UI surfaces the gap.
//

import Foundation

public struct TransactionDraft: Sendable, Equatable {
    public var amount: Double?
    public var summary: String?
    public var date: Date?
    public var kind: TransactionKind?
    public var categoryName: String?
    /// Names of participants the user mentioned (e.g. "with Bruno").
    /// The dictation handler resolves these against MainState.users
    /// and feeds the matches into AddTransactionState.participants.
    public var participantNames: [String]

    public init(
        amount: Double? = nil,
        summary: String? = nil,
        date: Date? = nil,
        kind: TransactionKind? = nil,
        categoryName: String? = nil,
        participantNames: [String] = []
    ) {
        self.amount = amount
        self.summary = summary
        self.date = date
        self.kind = kind
        self.categoryName = categoryName
        self.participantNames = participantNames
    }

    /// `true` when any of the required fields is still missing.
    /// Drives the `needsReview` flag on persisted transactions.
    /// Date + participants are optional enrichments and don't gate
    /// the review flag — the user is fine without them.
    public var needsReview: Bool {
        amount == nil || summary == nil || kind == nil || categoryName == nil
    }
}

public protocol TransactionDictationUseCase: Sendable {
    /// Best-effort parse of a spoken utterance into a draft.
    /// Implementations must never throw — failures degrade to a
    /// draft with `needsReview == true`.
    func parse(_ utterance: String) async -> TransactionDraft
}
