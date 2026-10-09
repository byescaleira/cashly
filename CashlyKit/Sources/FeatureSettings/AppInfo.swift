import Foundation

public struct AppInfo: Sendable {
    public static let main = AppInfo(info: Bundle.main.infoDictionary ?? [:])

    let version: String
    let appStoreURL: URL?
    let reviewURL: URL?
    let supportURL: URL?
    let helpURL: URL?
    let privacyURL: URL?
    let termsURL: URL?

    public init(info: [String: Any]) {
        func value(_ key: String) -> String? {
            (info[key] as? String).flatMap { $0.isEmpty ? nil : $0 }
        }
        let number = value("CFBundleShortVersionString") ?? "—"
        version = value("CFBundleVersion").map { "\(number) (\($0))" } ?? number
        let store = value("CashlyAppStoreID").map { "https://apps.apple.com/app/id\($0)" }
        appStoreURL = store.flatMap(URL.init(string:))
        reviewURL = store.flatMap { URL(string: $0 + "?action=write-review") }
        supportURL = value("CashlySupportEmail").flatMap { URL(string: "mailto:\($0)") }
        helpURL = value("CashlyHelpURL").flatMap(URL.init(string:))
        privacyURL = value("CashlyPrivacyURL").flatMap(URL.init(string:))
        termsURL = value("CashlyTermsURL").flatMap(URL.init(string:))
    }

    var hasHelp: Bool { reviewURL != nil || supportURL != nil || helpURL != nil }
}
