//
//  UsageLabel.swift
//  CashlyKit
//
//  Locale-aware "n / N" formatter used by Free-tier usage chips.
//  Keeps formatting in a single place so the string `%lld of %lld`
//  (or the localized equivalent) can be tuned per language via
//  Localizable.xcstrings without touching call sites.
//

import Foundation

public enum UsageLabel {
    /// Localized "current of max" label. Numbers go through
    /// `IntegerFormatStyle` so locale-specific separators (e.g.
    /// thin space for fr-FR) are honoured. The separator between
    /// the two numbers comes from the locale's language code: a
    /// slash for most Western locales, "de" for Portuguese.
    public static func format(current: Int, max: Int, locale: Locale = .current) -> String {
        let style = IntegerFormatStyle<Int>().locale(locale)
        let currentText = current.formatted(style)
        let maxText = max.formatted(style)
        let sep = separator(in: locale)
        return "\(currentText)\(sep)\(maxText)"
    }

    private static func separator(in locale: Locale) -> String {
        switch locale.language.languageCode?.identifier {
        case "pt": return " de "
        default: return "/"
        }
    }
}
