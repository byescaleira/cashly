//
//  TransactionKind+Localized.swift
//  CashlyKit
//
//  UI-side localization helper. TransactionKind lives in Domain so
//  the raw `summary` returns an untranslated English string; this
//  extension routes it through the resource bundle for display.
//

import Foundation
import CashlyDomain
import CashlyResource

public extension TransactionKind {
    /// Localized display string. Maps each case to a stable string-
    /// catalog key so translations don't depend on the raw enum
    /// summary changing.
    var localizedSummary: String {
        switch self {
        case .expense: return CashlyL10n.string("Expense")
        case .income: return CashlyL10n.string("Income")
        case .loan: return CashlyL10n.string("Loan")
        }
    }
}
