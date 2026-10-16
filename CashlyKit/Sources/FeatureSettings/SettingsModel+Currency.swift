import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import Foundation
import SwiftUI

struct CurrencyChoice: Identifiable, Equatable {
    let from: String
    let to: String

    var id: String { "\(from)-\(to)" }
}

extension SettingsModel {
    static let sampleAmount = Decimal(123_456) / 100

    static var deviceRegions: [Locale.Region] {
        [Locale.current.region, Locale.app.region].compactMap { $0 }
    }

    func currencySymbol(_ code: String) -> String {
        CurrencyText.symbol(code)
    }

    func currencySample(_ code: String) -> String {
        Self.sampleAmount.formatted(.currency(code: code).locale(.app))
    }

    var currencyValue: String { "\(currencySymbol(currency)) · \(currency)" }

    func suggestedCurrencies(regions: [Locale.Region] = deviceRegions) -> [String] {
        var codes: [String] = []
        for region in regions {
            guard let code = Locale(identifier: "en_\(region.identifier)").currency?.identifier,
                CurrencySetting.isSupported(code),
                !codes.contains(code)
            else { continue }
            codes.append(code)
        }
        return codes
    }

    func otherCurrencies(regions: [Locale.Region] = deviceRegions) -> [String] {
        let suggested = suggestedCurrencies(regions: regions)
        return CurrencySetting.supported.filter { !suggested.contains($0) }.sorted {
            currencyName($0).localizedStandardCompare(currencyName($1)) == .orderedAscending
        }
    }

    func currencies(matching query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return CurrencySetting.supported }
        return CurrencySetting.supported.filter {
            $0.localizedStandardContains(trimmed)
                || currencyName($0).localizedStandardContains(trimmed)
                || currencySymbol($0).localizedStandardContains(trimmed)
        }
    }

    func choose(currency code: String) {
        guard code != currency, CurrencySetting.isSupported(code) else { return }
        currencyChoice = CurrencyChoice(from: currency, to: code)
    }

    func confirmCurrencyChoice() async {
        guard let choice = currencyChoice, !isFetchingCorrection else { return }
        isFetchingCorrection = true
        let correction = await fetchCorrection(to: choice.to)
        isFetchingCorrection = false
        guard currencyChoice == choice else { return }
        apply(correction)
        currency = choice.to
        correctionFailed = correction == nil
        currencyChoice = nil
    }

    func retryCorrection() async {
        guard !isFetchingCorrection else { return }
        isFetchingCorrection = true
        let correction = await fetchCorrection(to: currency)
        isFetchingCorrection = false
        guard let correction else {
            correctionFailed = true
            return
        }
        apply(correction)
        correctionFailed = false
    }

    public func prepareCorrection() async {
        guard correction == nil, !isFetchingCorrection else { return }
        isFetchingCorrection = true
        let fetched = await fetchCorrection(to: currency)
        isFetchingCorrection = false
        guard let fetched, fetched.target == currency, correction == nil else { return }
        apply(fetched)
    }

    var correction: CurrencyCorrection? {
        currencySetting.correction.flatMap { $0.target == currency ? $0 : nil }
    }

    var correctionStatus: CorrectionStatus {
        if correctionFailed {
            return CorrectionStatus(
                symbol: "exclamationmark.arrow.circlepath", color: .warning,
                title: String(appLocalized: "Rates unavailable"),
                detail: String(
                    appLocalized:
                        "Cashly couldn't get exchange rates. Amounts saved in other currencies show without conversion."
                ), canRetry: true)
        }
        guard let date = correction?.date else {
            return CorrectionStatus(
                symbol: "arrow.left.arrow.right", color: .retroOlive,
                title: String(appLocalized: "Shown converted"),
                detail: String(
                    appLocalized:
                        "When you switch currency, amounts saved in the previous one appear converted at the rate of that moment. What you saved stays as it is."
                ), canRetry: false)
        }
        let moment = date.formatted(
            .dateTime.day().month(.abbreviated).hour().minute().locale(.app))
        return CorrectionStatus(
            symbol: "arrow.left.arrow.right", color: .retroOlive,
            title: String(appLocalized: "Shown converted"),
            detail: String(
                appLocalized:
                    "Amounts saved in other currencies use the rates from \(moment). Banks apply their own rates, fees and dates, so treat them as estimates."
            ), canRetry: false)
    }

    private func fetchCorrection(to code: String) async -> CurrencyCorrection? {
        guard let table = try? await rates.table(base: code, on: nil) else { return nil }
        return CurrencyCorrection(table: table, codes: CurrencySetting.supported)
    }

    private func apply(_ correction: CurrencyCorrection?) {
        currencySetting.correction = correction
        if let correction, let data = try? JSONEncoder().encode(correction) {
            defaults.set(data, forKey: Key.currencyCorrection)
        } else {
            defaults.removeObject(forKey: Key.currencyCorrection)
        }
    }

    func choiceNotes(_ choice: CurrencyChoice) -> [SettingsNote] {
        [
            SettingsNote(
                title: String(appLocalized: "Shown converted"),
                detail: String(
                    appLocalized:
                        "Records saved in \(currencyName(choice.from)) appear converted at the current rate, as an estimate. The original amounts stay saved as they are."
                )),
            SettingsNote(
                title: String(appLocalized: "New records"),
                detail: String(
                    appLocalized:
                        "From now on, new records are saved in \(currencyName(choice.to)).")),
        ]
    }

    func cancelCurrencyChoice() {
        guard !isFetchingCorrection else { return }
        currencyChoice = nil
    }
}
