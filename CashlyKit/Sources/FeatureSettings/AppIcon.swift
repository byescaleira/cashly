import Foundation

public enum AppIcon: String, CaseIterable, Identifiable, Sendable {
    case standard, dark, orange, graphite

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
        }
    }

    var title: String {
        switch self {
        case .standard: "Verde"
        case .dark: "Escuro"
        case .orange: "Laranja"
        case .graphite: "Grafite"
        }
    }
}
