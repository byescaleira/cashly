import Foundation
import Testing

@testable import FeatureSettings

struct AppInfoTests {
    @Test func buildsLinksFromConfiguredKeys() {
        let info = AppInfo(info: [
            "CFBundleShortVersionString": "1.2", "CFBundleVersion": "34",
            "CashlyAppStoreID": "123", "CashlySupportEmail": "ajuda@cashly.app",
            "CashlyHelpURL": "https://cashly.app/ajuda",
            "CashlyPrivacyURL": "https://cashly.app/privacidade",
            "CashlyTermsURL": "https://cashly.app/termos",
        ])
        #expect(info.version == "1.2 (34)")
        #expect(info.appStoreURL?.absoluteString == "https://apps.apple.com/app/id123")
        #expect(
            info.reviewURL?.absoluteString == "https://apps.apple.com/app/id123?action=write-review"
        )
        #expect(info.supportURL?.absoluteString == "mailto:ajuda@cashly.app")
        #expect(info.helpURL?.absoluteString == "https://cashly.app/ajuda")
        #expect(info.privacyURL?.absoluteString == "https://cashly.app/privacidade")
        #expect(info.termsURL?.absoluteString == "https://cashly.app/termos")
        #expect(info.hasHelp)
        #expect(info.links.map(\.kind) == [.help, .contact, .privacy, .terms])
    }

    @Test func websiteLeadsTheLinks() {
        let info = AppInfo(info: [
            "CashlyWebsiteURL": "https://cashly.app", "CashlyTermsURL": "https://cashly.app/termos",
        ])
        #expect(info.websiteURL?.absoluteString == "https://cashly.app")
        #expect(info.links.map(\.kind) == [.website, .terms])
    }

    @Test func emptyKeysHideLinks() {
        let info = AppInfo(info: ["CashlyAppStoreID": "", "CashlySupportEmail": ""])
        #expect(info.version == "—")
        #expect(info.appStoreURL == nil)
        #expect(info.supportURL == nil)
        #expect(!info.hasHelp)
        #expect(info.links.isEmpty)
    }
}
