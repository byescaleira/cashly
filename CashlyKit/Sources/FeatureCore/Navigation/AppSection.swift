import SwiftUI

public enum AppSection: String, CaseIterable, Identifiable {
    case home, transaction, planning, settings, search

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .home: "Início"
        case .transaction: "Histórico"
        case .planning: "Metas"
        case .settings: "Ajustes"
        case .search: "Buscar"
        }
    }

    public var systemImage: String {
        switch self {
        case .home: "house"
        case .transaction: "list.bullet.rectangle"
        case .planning: "calendar.badge.clock"
        case .settings: "gearshape"
        case .search: "magnifyingglass"
        }
    }

    public var role: TabRole? {
        switch self {
        case .search: .prominent
        default: nil
        }
    }
}
