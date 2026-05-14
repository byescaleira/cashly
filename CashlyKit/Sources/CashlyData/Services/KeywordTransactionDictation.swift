//
//  KeywordTransactionDictation.swift
//  CashlyKit
//
//  Stub TransactionDictationUseCase that runs a small regex-based
//  parser instead of a real LLM. Lets the J8 ondas wire the
//  dictation pipeline end-to-end without depending on Apple
//  Intelligence; J9 will swap in the Foundation Models impl.
//
//  Heuristics:
//  - amount = first number with optional decimal point in the
//    utterance (locale-independent — strips R$ / $ prefixes)
//  - kind = "recebi" / "received" → income, "emprestei" / "lent" →
//    loan, otherwise default expense
//  - summary = utterance minus the parsed amount, trimmed
//  - categoryName = nil (the LLM impl will infer it; stub doesn't)
//

import Foundation
import CashlyDomain

public struct KeywordTransactionDictation: TransactionDictationUseCase {
    public init() {}

    public func parse(_ utterance: String) async -> TransactionDraft {
        let lowered = utterance.lowercased()
        let amount = Self.firstNumber(in: utterance)
        let kind = Self.inferKind(from: lowered)
        let summary = Self.summary(from: utterance, removingAmount: amount)
        let date = Self.inferDate(from: lowered)
        let participants = Self.inferParticipants(from: utterance)

        return TransactionDraft(
            amount: amount,
            summary: summary.isEmpty ? nil : summary,
            date: date,
            kind: kind,
            categoryName: nil,
            participantNames: participants
        )
    }

    // MARK: - Helpers

    private static func firstNumber(in source: String) -> Double? {
        // Accept comma OR dot as decimal separator; pick the first
        // number-shaped token so "I spent 12,50 at the store" yields
        // 12.50.
        let pattern = #"-?\d+(?:[.,]\d+)?"#
        guard let range = source.range(of: pattern, options: .regularExpression) else { return nil }
        let raw = source[range].replacingOccurrences(of: ",", with: ".")
        return Double(raw)
    }

    private static func inferKind(from lowered: String) -> TransactionKind? {
        let incomeMarkers = ["recebi", "received", "income", "salary", "salário"]
        let loanMarkers = ["emprestei", "loan", "lent", "borrowed", "emprestado"]
        if incomeMarkers.contains(where: { lowered.contains($0) }) { return .income }
        if loanMarkers.contains(where: { lowered.contains($0) }) { return .loan }
        return .expense
    }

    private static func inferDate(from lowered: String) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        if lowered.contains("ontem") || lowered.contains("yesterday") {
            return calendar.date(byAdding: .day, value: -1, to: now)
        }
        if lowered.contains("anteontem") {
            return calendar.date(byAdding: .day, value: -2, to: now)
        }
        if lowered.contains("hoje") || lowered.contains("today") {
            return now
        }
        if lowered.contains("amanhã") || lowered.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        }
        return nil
    }

    private static func inferParticipants(from source: String) -> [String] {
        // Match "with X", "with X and Y", "com X", "com X e Y".
        let pattern = #"(?:with|com)\s+([A-ZÀ-Úa-zà-ú][\wÀ-ú]+(?:\s+(?:and|e)\s+[A-ZÀ-Úa-zà-ú][\wÀ-ú]+)*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        let range = NSRange(source.startIndex..., in: source)
        guard let match = regex.firstMatch(in: source, range: range),
              match.numberOfRanges >= 2,
              let captureRange = Range(match.range(at: 1), in: source)
        else { return [] }
        let captured = String(source[captureRange])
        return captured
            .replacingOccurrences(of: " and ", with: ",")
            .replacingOccurrences(of: " e ", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func summary(from source: String, removingAmount amount: Double?) -> String {
        guard let amount else {
            return source.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Strip both the dot and comma encodings of the amount.
        let dot = String(format: "%g", amount)
        let comma = dot.replacingOccurrences(of: ".", with: ",")
        return source
            .replacingOccurrences(of: dot, with: "")
            .replacingOccurrences(of: comma, with: "")
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
