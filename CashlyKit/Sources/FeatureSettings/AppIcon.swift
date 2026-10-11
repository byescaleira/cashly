import Foundation

public enum AppIcon: String, CaseIterable, Identifiable, Sendable {
    case standard, dark, orange, graphite, blood, bat, skull, frankenstein

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
}
