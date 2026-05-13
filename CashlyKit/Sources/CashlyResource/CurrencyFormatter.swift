//
//  CurrencyFormatter.swift
//  CashlyKit
//
//  Centralised currency formatting. Reads the active currency code
//  from UserDefaults (`cashly.currencyCode`) and formats every
//  amount with `Locale.current` so digit grouping + decimal marks
//  follow the user's region while the symbol follows the chosen
//  currency.
//

import Foundation

public enum CashlyCurrency {
    public static let userDefaultsKey = "cashly.currencyCode"
    public static let `default` = "USD"

    /// Returns the currency code currently active. Falls back to
    /// `default` when the user hasn't picked one explicitly.
    public static func current(suite: UserDefaults = .standard) -> String {
        suite.string(forKey: userDefaultsKey) ?? `default`
    }

    /// Formats `amount` as a currency string using the active
    /// currency. Pass a `code` explicitly to override the user
    /// preference (used by tests + CSV export).
    public static func format(
        _ amount: Double,
        code: String? = nil,
        locale: Locale = .current,
        suite: UserDefaults = .standard
    ) -> String {
        let resolvedCode = code ?? current(suite: suite)
        return amount.formatted(.currency(code: resolvedCode).locale(locale))
    }

    /// Convenient list of common currency codes for picker UIs.
    /// Not exhaustive — `Locale.commonISOCurrencyCodes` covers the
    /// rest if the user types one in manually.
    public static let common: [String] = [
        "USD", "EUR", "GBP", "BRL", "JPY", "CAD", "AUD", "CHF", "CNY", "MXN"
    ]
}
