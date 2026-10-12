import Foundation

public enum AppIcon: String, CaseIterable, Identifiable, Sendable {
    case standard, dark, orange, graphite
    case jeans, tailoring, leather
    case brazil, portugal, argentina
    case football, basketball, tennis
    case bunting, plaid
    case blood, bat, skull, frankenstein
    case gift, snow

    public enum Collection: CaseIterable, Sendable {
        case colors, fashion, countries, sports, junina, halloween, christmas

        var title: String {
            switch self {
            case .colors: "Cores"
            case .fashion: "Moda"
            case .countries: "Países"
            case .sports: "Esportes"
            case .junina: "Festa Junina"
            case .halloween: "Halloween"
            case .christmas: "Natal"
            }
        }

        var month: Int? {
            switch self {
            case .colors, .fashion, .countries, .sports: nil
            case .junina: 6
            case .halloween: 10
            case .christmas: 12
            }
        }

        var icons: [AppIcon] { AppIcon.allCases.filter { $0.collection == self } }
    }

    public var id: String { rawValue }

    public init(assetName: String?) {
        self = Self.allCases.first { $0.assetName == assetName } ?? .standard
    }

    public var assetName: String? {
        switch self {
        case .standard: nil
        case .dark: "CashlyIconDark"
        case .orange: "CashlyIconOrange"
        case .graphite: "CashlyIconGraphite"
        case .jeans: "CashlyIconJeans"
        case .tailoring: "CashlyIconTailoring"
        case .leather: "CashlyIconLeather"
        case .brazil: "CashlyIconBrazil"
        case .portugal: "CashlyIconPortugal"
        case .argentina: "CashlyIconArgentina"
        case .football: "CashlyIconFootball"
        case .basketball: "CashlyIconBasketball"
        case .tennis: "CashlyIconTennis"
        case .bunting: "CashlyIconBunting"
        case .plaid: "CashlyIconPlaid"
        case .blood: "CashlyIconBlood"
        case .bat: "CashlyIconBat"
        case .skull: "CashlyIconSkull"
        case .frankenstein: "CashlyIconFrankenstein"
        case .gift: "CashlyIconGift"
        case .snow: "CashlyIconSnow"
        }
    }

    var previewName: String { assetName ?? "CashlyIcon" }

    var collection: Collection {
        switch self {
        case .standard, .dark, .orange, .graphite: .colors
        case .jeans, .tailoring, .leather: .fashion
        case .brazil, .portugal, .argentina: .countries
        case .football, .basketball, .tennis: .sports
        case .bunting, .plaid: .junina
        case .blood, .bat, .skull, .frankenstein: .halloween
        case .gift, .snow: .christmas
        }
    }

    var title: String {
        switch self {
        case .standard: "Clássico"
        case .dark: "Noturno"
        case .orange: "Mostarda"
        case .graphite: "Petróleo"
        case .jeans: "Jeans"
        case .tailoring: "Alfaiataria"
        case .leather: "Couro"
        case .brazil: "Brasil"
        case .portugal: "Portugal"
        case .argentina: "Argentina"
        case .football: "Futebol"
        case .basketball: "Basquete"
        case .tennis: "Tênis"
        case .bunting: "Bandeirinhas"
        case .plaid: "Xadrez"
        case .blood: "Sangue"
        case .bat: "Morcego"
        case .skull: "Caveira"
        case .frankenstein: "Frankenstein"
        case .gift: "Presente"
        case .snow: "Neve"
        }
    }

    static func featured(on date: Date, calendar: Calendar = .current) -> Collection? {
        let month = calendar.component(.month, from: date)
        return Collection.allCases.first { $0.month == month }
    }
}
