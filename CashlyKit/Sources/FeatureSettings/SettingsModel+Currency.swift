import CashlyDomain
import Foundation

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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .app
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
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

    func confirmCurrencyChoice() {
        if let choice = currencyChoice { currency = choice.to }
        currencyChoice = nil
    }

    func choiceNotes(_ choice: CurrencyChoice) -> [SettingsNote] {
        [
            SettingsNote(
                title: String(appLocalized: "Nothing is converted"),
                detail: String(
                    appLocalized:
                        "\(currencySample(choice.from)) becomes \(currencySample(choice.to)). Only the symbol changes."
                )),
            SettingsNote(
                title: String(appLocalized: "New records"),
                detail: String(
                    appLocalized:
                        "From now on, new records are saved in \(currencyName(choice.to)).")),
        ]
    }

    func cancelCurrencyChoice() {
        currencyChoice = nil
    }
}
