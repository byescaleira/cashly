//
//  CashlyResourceString.swift
//  CashlyKit
//
//  Typed accessor for Localizable.xcstrings. Call sites use
//  `CashlyL10n.string("Save")` instead of inline string literals so
//  the strings catalog can pick them up.
//

import Foundation

public enum CashlyL10n {
    /// Localized value for the given key from CashlyResource's Localizable.xcstrings.
    /// Falls back to the key itself if missing.
    public static func string(_ key: String.LocalizationValue, comment: StaticString? = nil) -> String {
        String(localized: key, bundle: .module, comment: comment)
    }
}
