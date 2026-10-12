import CashlyDomain
import SwiftUI

public enum AppSection: String, CaseIterable, Identifiable {
    case home, transaction, planning, settings, journey

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .home: String(appLocalized: "Home")
        case .transaction: String(appLocalized: "History")
        case .planning: String(appLocalized: "Goals")
        case .journey: String(appLocalized: "Journey")
        case .settings: String(appLocalized: "Settings")
        }
    }

    public var systemImage: String {
        switch self {
        case .home: "house"
        case .transaction: "list.bullet.rectangle"
        case .planning: "calendar.badge.clock"
        case .journey: "trophy"
        case .settings: "gearshape"
        }
    }

    public var role: TabRole? {
        switch self {
        case .journey: .prominent
        default: nil
        }
    }
}
