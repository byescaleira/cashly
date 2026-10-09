import Foundation

public enum AppSection: String, CaseIterable, Identifiable {
    case home, transaction, planning, reports, search
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .home: "Início"
        case .transaction: "Transações"
        case .planning: "Planejamento"
        case .reports: "Relatórios"
        case .search: "Buscar"
        }
    }
    public var systemImage: String {
        switch self {
        case .home: "house"
        case .transaction: "arrow.left.arrow.right"
        case .planning: "chart.pie"
        case .reports: "chart.xyaxis.line"
        case .search: "magnifyingglass"
        }
    }
    public static var tabs: [AppSection] { allCases.filter { $0 != .search } }
}
