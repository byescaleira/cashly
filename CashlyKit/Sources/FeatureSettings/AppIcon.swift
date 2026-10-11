import Foundation

public enum AppIcon: String, CaseIterable, Identifiable, Sendable {
    case standard, dark, orange, graphite, blood, bat, skull, frankenstein

    public enum Collection: CaseIterable, Sendable {
        case colors, halloween

        var title: String {
            switch self {
            case .colors: "Cores"
            case .halloween: "Halloween"
            }
        }

        var month: Int? {
            switch self {
            case .colors: nil
            case .halloween: 10
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
        case .blood: "CashlyIconBlood"
        case .bat: "CashlyIconBat"
        case .skull: "CashlyIconSkull"
        case .frankenstein: "CashlyIconFrankenstein"
        }
    }

    var previewName: String { assetName ?? "CashlyIcon" }

    var collection: Collection {
        switch self {
        case .standard, .dark, .orange, .graphite: .colors
        case .blood, .bat, .skull, .frankenstein: .halloween
        }
    }

    var title: String {
        switch self {
        case .standard: "Clássico"
        case .dark: "Noturno"
        case .orange: "Mostarda"
        case .graphite: "Petróleo"
        case .blood: "Sangue"
        case .bat: "Morcego"
        case .skull: "Caveira"
        case .frankenstein: "Frankenstein"
        }
    }

    static func featured(on date: Date, calendar: Calendar = .current) -> Collection? {
        let month = calendar.component(.month, from: date)
        return Collection.allCases.first { $0.month == month }
    }
}
