import SwiftUI

public enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Automático"
        case .light: "Claro"
        case .dark: "Escuro"
        }
    }
}
