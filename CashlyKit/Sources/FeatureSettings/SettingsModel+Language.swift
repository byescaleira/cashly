import CashlyDomain
import Foundation

struct LanguagePreview: Equatable {
    let date: String
    let amount: String
    let sentence: String
}

extension AppLanguage {
    var glyph: String {
        switch self {
        case .system: ""
        case .english: "Aa"
        case .portuguese: "Ão"
        case .spanish: "Ñ"
        case .german: "Ä"
        case .french: "É"
        case .italian: "È"
        case .japanese: "あ"
        case .korean: "한"
        case .chinese: "中"
        case .russian: "Я"
        }
    }
}

extension SettingsModel {
    static var devicePreferences: [String] {
        UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?[
            "AppleLanguages"] as? [String] ?? Locale.preferredLanguages
    }

    func deviceLanguage(preferences: [String] = SettingsModel.devicePreferences) -> AppLanguage? {
        Bundle.preferredLocalizations(
            from: AppLanguage.languages.map(\.rawValue), forPreferences: preferences
        )
        .first.flatMap(AppLanguage.init(rawValue:))
    }

    func translatedName(of language: AppLanguage) -> String? {
        guard language != .system,
            let name = Locale.app.localizedString(forIdentifier: language.rawValue)
        else { return nil }
        let capitalized = name.prefix(1).uppercased() + name.dropFirst()
        return capitalized == language.nativeName ? nil : capitalized
    }

    func languageDetail(of language: AppLanguage, preferences: [String] = devicePreferences)
        -> String?
    {
        guard language == .system else { return translatedName(of: language) }
        return deviceLanguage(preferences: preferences).map {
            String(appLocalized: "Follows your device: \($0.nativeName)")
        }
    }

    func shortName(of language: AppLanguage) -> String {
        let locale = Locale(identifier: language.code)
        let name = locale.localizedString(forLanguageCode: language.code) ?? language.nativeName
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    var languageValue: String {
        guard language == .system else { return shortName(of: language) }
        return String(appLocalized: "System · \(shortName(of: language))")
    }

    func languagePreview(of language: AppLanguage, on date: Date = .now) -> LanguagePreview {
        let locale = language.locale
        let amount = Decimal(184_250) / 100
        let formatted = amount.formatted(.currency(code: currency).locale(locale))
        return LanguagePreview(
            date: date.formatted(
                Date.FormatStyle(locale: locale).weekday(.wide).day().month(.wide)),
            amount: formatted,
            sentence: String(
                localized: "You still have \(formatted) to spend this month.",
                bundle: language.bundle, locale: locale))
    }
}
