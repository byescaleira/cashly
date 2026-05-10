//
//  CashlyResourceString.swift
//  CashlyKit
//
//  Wave 7 G020: typed accessor for Localizable.xcstrings in CashlyResource.
//  Use `CashlyL10n.save` instead of "Save" in user-facing UI strings.
//

import Foundation

public enum CashlyL10n {
    /// Localized value for the given key from CashlyResource's Localizable.xcstrings.
    /// Falls back to the key itself if missing.
    public static func string(_ key: String.LocalizationValue, comment: StaticString? = nil) -> String {
        String(localized: key, bundle: .module, comment: comment)
    }
}
