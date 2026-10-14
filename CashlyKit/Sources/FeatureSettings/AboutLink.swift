import Foundation
import SwiftUI

struct AboutLink: Identifiable {
    enum Kind {
        case contact, help, privacy, terms
    }

    let kind: Kind
    let url: URL

    var id: Kind { kind }

    var title: LocalizedStringKey {
        switch kind {
        case .contact: "Contact Us"
        case .help: "Help Center"
        case .privacy: "Privacy Policy"
        case .terms: "Terms of Use"
        }
    }

    var symbol: String {
        switch kind {
        case .contact: "envelope"
        case .help: "questionmark.circle"
        case .privacy: "hand.raised"
        case .terms: "doc.text"
        }
    }

    var usesTint: Bool {
        switch kind {
        case .contact, .privacy: false
        case .help, .terms: true
        }
    }
}

extension AppInfo {
    var links: [AboutLink] {
        let pairs: [(AboutLink.Kind, URL?)] = [
            (.contact, supportURL), (.help, helpURL), (.privacy, privacyURL), (.terms, termsURL),
        ]
        return pairs.compactMap { kind, url in url.map { AboutLink(kind: kind, url: $0) } }
    }
}
