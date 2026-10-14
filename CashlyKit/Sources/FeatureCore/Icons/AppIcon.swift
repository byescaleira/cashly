import CashlyDomain
import Foundation

public enum AppIcon: String, CaseIterable, Identifiable, Sendable {
    case standard, dark, orange, graphite
    case jeans, tailoring, leather, polkaDot
    case brazil, portugal, argentina, japan
    case football, basketball, tennis, volleyball
    case neon, cassette, arcade, handheld
    case sunset, boardwalk, parasol, watermelon
    case confetti, streamer, frevo, sequin
    case bunting, plaid, bonfire, corn
    case blood, bat, skull, frankenstein
    case gift, snow, lights, candyCane

    public enum Collection: CaseIterable, Sendable {
        case colors, fashion, countries, sports, eighties
        case summer, carnival, junina, halloween, christmas

        public var title: String {
            switch self {
            case .colors: String(appLocalized: "Colors")
            case .fashion: String(appLocalized: "Fashion")
            case .countries: String(appLocalized: "Countries")
            case .sports: String(appLocalized: "Sports")
            case .eighties: String(appLocalized: "The ’80s")
            case .summer: String(appLocalized: "Summer")
            case .carnival: String(appLocalized: "Carnival")
            case .junina: String(appLocalized: "Festa Junina")
            case .halloween: String(appLocalized: "Halloween")
            case .christmas: String(appLocalized: "Christmas")
            }
        }

        var month: Int? {
            switch self {
            case .colors, .fashion, .countries, .sports, .eighties: nil
            case .summer: 1
            case .carnival: 2
            case .junina: 6
            case .halloween: 10
            case .christmas: 12
            }
        }

        public var icons: [AppIcon] { AppIcon.allCases.filter { $0.collection == self } }

        public var shopItem: ShopItem? {
            switch self {
            case .colors: nil
            case .fashion: .iconsFashion
            case .countries: .iconsCountries
            case .sports: .iconsSports
            case .eighties: .iconsEighties
            case .summer: .iconsSummer
            case .carnival: .iconsCarnival
            case .junina: .iconsJunina
            case .halloween: .iconsHalloween
            case .christmas: .iconsChristmas
            }
        }
    }

    public var id: String { rawValue }

    public init(assetName: String?) {
        self = Self.allCases.first { $0.assetName == assetName } ?? .standard
    }

    public var assetName: String? {
        switch self {
        case .standard: nil
        default: "CashlyIcon" + rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }

    public var previewName: String { assetName ?? "CashlyIcon" }

    public var shopItem: ShopItem? { collection.shopItem }

    public static func icons(of item: ShopItem) -> [AppIcon] {
        if item == .iconsAll {
            return Collection.allCases.filter { $0.shopItem != nil }.flatMap(\.icons)
        }
        return Collection.allCases.first { $0.shopItem == item }?.icons ?? []
    }

    public var collection: Collection {
        switch self {
        case .standard, .dark, .orange, .graphite: .colors
        case .jeans, .tailoring, .leather, .polkaDot: .fashion
        case .brazil, .portugal, .argentina, .japan: .countries
        case .football, .basketball, .tennis, .volleyball: .sports
        case .neon, .cassette, .arcade, .handheld: .eighties
        case .sunset, .boardwalk, .parasol, .watermelon: .summer
        case .confetti, .streamer, .frevo, .sequin: .carnival
        case .bunting, .plaid, .bonfire, .corn: .junina
        case .blood, .bat, .skull, .frankenstein: .halloween
        case .gift, .snow, .lights, .candyCane: .christmas
        }
    }

    public var title: String {
        switch self {
        case .standard: String(appLocalized: "Classic")
        case .dark: String(appLocalized: "Night")
        case .orange: String(appLocalized: "Mustard")
        case .graphite: String(appLocalized: "Teal")
        case .jeans: String(appLocalized: "Denim")
        case .tailoring: String(appLocalized: "Tailoring")
        case .leather: String(appLocalized: "Leather")
        case .polkaDot: String(appLocalized: "Polka Dot")
        case .brazil: String(appLocalized: "Brazil")
        case .portugal: String(appLocalized: "Portugal")
        case .argentina: String(appLocalized: "Argentina")
        case .japan: String(appLocalized: "Japan")
        case .football: String(appLocalized: "Soccer")
        case .basketball: String(appLocalized: "Basketball")
        case .tennis: String(appLocalized: "Tennis")
        case .volleyball: String(appLocalized: "Volleyball")
        case .neon: String(appLocalized: "Neon")
        case .cassette: String(appLocalized: "Cassette")
        case .arcade: String(appLocalized: "Arcade")
        case .handheld: String(appLocalized: "Handheld")
        case .sunset: String(appLocalized: "Sunset")
        case .boardwalk: String(appLocalized: "Boardwalk")
        case .parasol: String(appLocalized: "Beach Umbrella")
        case .watermelon: String(appLocalized: "Watermelon")
        case .confetti: String(appLocalized: "Confetti")
        case .streamer: String(appLocalized: "Streamers")
        case .frevo: String(appLocalized: "Frevo")
        case .sequin: String(appLocalized: "Sequins")
        case .bunting: String(appLocalized: "Bunting")
        case .plaid: String(appLocalized: "Plaid")
        case .bonfire: String(appLocalized: "Bonfire")
        case .corn: String(appLocalized: "Corn")
        case .blood: String(appLocalized: "Blood")
        case .bat: String(appLocalized: "Bat")
        case .skull: String(appLocalized: "Skull")
        case .frankenstein: String(appLocalized: "Frankenstein")
        case .gift: String(appLocalized: "Gift")
        case .snow: String(appLocalized: "Snow")
        case .lights: String(appLocalized: "Lights")
        case .candyCane: String(appLocalized: "Candy Cane")
        }
    }

    public static func featured(on date: Date, calendar: Calendar = .current) -> Collection? {
        let month = calendar.component(.month, from: date)
        return Collection.allCases.first { $0.month == month }
    }
}
