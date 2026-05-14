//
//  StringFuzzyMatch.swift
//  CashlyKit
//
//  Lightweight fuzzy match used by the dictation flow to resolve
//  spoken category labels against the user's existing categories.
//  Ladder of three strategies, cheap → expensive:
//
//  1. Case-insensitive equality
//  2. Substring containment in either direction (handles "mercado"
//     → "Supermercado" and vice versa)
//  3. Normalised Levenshtein distance under a configurable
//     threshold (defaults to 0.4 — roughly "fewer than 40% of the
//     longer string's characters need to change")
//

import Foundation

public enum CashlyFuzzyMatch {
    public static let defaultThreshold: Double = 0.4

    /// Returns the candidate that best matches `needle` from the
    /// `haystack`, or nil when nothing meets the threshold.
    public static func bestMatch<Item>(
        for needle: String,
        in haystack: [Item],
        key: (Item) -> String,
        threshold: Double = defaultThreshold
    ) -> Item? {
        guard !needle.isEmpty, !haystack.isEmpty else { return nil }
        let normalisedNeedle = normalise(needle)

        if let exact = haystack.first(where: { normalise(key($0)) == normalisedNeedle }) {
            return exact
        }
        if let substring = haystack.first(where: {
            let candidate = normalise(key($0))
            return candidate.contains(normalisedNeedle) || normalisedNeedle.contains(candidate)
        }) {
            return substring
        }
        return haystack
            .map { item -> (Item, Double) in
                (item, normalisedDistance(needle: normalisedNeedle, candidate: normalise(key(item))))
            }
            .filter { $0.1 <= threshold }
            .min { $0.1 < $1.1 }?
            .0
    }

    /// Normalised edit distance in `[0, 1]`. 0 = identical.
    public static func normalisedDistance(
        needle: String,
        candidate: String
    ) -> Double {
        let longest = max(needle.count, candidate.count)
        guard longest > 0 else { return 0 }
        let distance = levenshtein(needle, candidate)
        return Double(distance) / Double(longest)
    }

    // MARK: - Helpers

    private static func normalise(_ source: String) -> String {
        source
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Classic two-row Levenshtein. O(n·m) time, O(min(n,m)) space —
    /// fine for the short strings we feed it (category names).
    private static func levenshtein(_ a: String, _ b: String) -> Int {
        let aChars = Array(a)
        let bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }

        var previous = Array(0 ... bChars.count)
        var current = Array(repeating: 0, count: bChars.count + 1)

        for i in 1 ... aChars.count {
            current[0] = i
            for j in 1 ... bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                current[j] = Swift.min(
                    current[j - 1] + 1,             // insert
                    previous[j] + 1,                // delete
                    previous[j - 1] + cost          // substitute
                )
            }
            swap(&previous, &current)
        }
        return previous[bChars.count]
    }
}
