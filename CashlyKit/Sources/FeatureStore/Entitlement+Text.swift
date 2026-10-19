import CashlyDomain
import FeatureCore
import Foundation

extension Entitlement {
    public var title: String {
        switch self {
        case .none: String(appLocalized: "Not Subscribed")
        case .trial: String(appLocalized: "Free Trial")
        case .active: String(appLocalized: "Active")
        case .expired: String(appLocalized: "Expired")
        }
    }

    public var detail: String? {
        switch self {
        case .none: nil
        case .trial(let date): String(appLocalized: "Trial ends on \(Self.day(date))")
        case .active(let date):
            date == .distantFuture ? nil : String(appLocalized: "Renews on \(Self.day(date))")
        case .expired(let date): String(appLocalized: "Expired on \(Self.day(date))")
        }
    }

    static func day(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: .app).day().month(.wide).year())
    }
}
