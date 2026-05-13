//
//  FoundationModelsTransactionDictation.swift
//  CashlyKit
//
//  Apple Intelligence-backed dictation. Uses the Foundation Models
//  framework's LanguageModelSession to do schema-guided generation
//  on-device. Only available on iOS 18.1+ devices with Apple
//  Intelligence enabled — every other build falls back to
//  KeywordTransactionDictation via the factory.
//
//  Why on-device only: amounts + summaries are sensitive financial
//  data; routing them through a network LLM would break the
//  privacy contract the app advertises.
//

import Foundation
import CashlyDomain
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(iOS 18.1, macOS 15.1, *)
public actor FoundationModelsTransactionDictation: TransactionDictationUseCase {
    public init() {}

    public func parse(_ utterance: String) async -> TransactionDraft {
        #if canImport(FoundationModels)
        // Probe availability at call time — the model can be
        // unavailable on a supported OS if the user disabled Apple
        // Intelligence or the device is in a constrained state
        // (Low Power Mode, thermal throttling).
        let model = SystemLanguageModel.default
        guard model.availability == .available else {
            return FoundationModelsTransactionDictation.fallbackDraft()
        }

        let session = LanguageModelSession(instructions: Self.instructions)
        do {
            let response = try await session.respond(
                to: utterance,
                generating: DictationOutput.self
            )
            return response.content.toDraft()
        } catch {
            // Quietly degrade — the dictation flow caller will see
            // needsReview=true and let the user fix what's missing.
            return FoundationModelsTransactionDictation.fallbackDraft()
        }
        #else
        return FoundationModelsTransactionDictation.fallbackDraft()
        #endif
    }

    private static func fallbackDraft() -> TransactionDraft {
        TransactionDraft()
    }

    private static let instructions = """
    You are a financial assistant. Parse the user's spoken sentence
    into a transaction record. Extract amount (number), summary
    (short description), kind (expense/income/loan), and a category
    label if mentioned. Use null for any field you cannot infer.
    Always answer in the structured format requested.
    """
}

#if canImport(FoundationModels)
@available(iOS 18.1, macOS 15.1, *)
@Generable
private struct DictationOutput: Equatable {
    @Guide(description: "Monetary value spoken by the user. Use the local decimal separator. Null when no amount is mentioned.")
    var amount: Double?

    @Guide(description: "Short human-readable summary of what the transaction is for. 3 to 60 characters.")
    var summary: String?

    @Guide(description: "Direction of the money flow. expense = money leaving, income = money coming in, loan = money lent out.")
    var kind: GenerableKind?

    @Guide(description: "Category label mentioned by the user (e.g. 'groceries', 'rent'). Null when not mentioned.")
    var category: String?

    func toDraft() -> TransactionDraft {
        TransactionDraft(
            amount: amount,
            summary: summary,
            date: nil,
            kind: kind.map { $0.toDomain },
            categoryName: category
        )
    }
}

@available(iOS 18.1, macOS 15.1, *)
@Generable
private enum GenerableKind: String, Equatable {
    case expense
    case income
    case loan

    var toDomain: TransactionKind {
        switch self {
        case .expense: return .expense
        case .income: return .income
        case .loan: return .loan
        }
    }
}
#endif
