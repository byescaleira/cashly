import CashlyDomain
import FeatureCore
import FeatureStore
import Foundation

struct SettingsNote: Identifiable, Equatable {
    let title: String
    let detail: String

    var id: String { title }
}

struct PlanBadge: Equatable {
    enum Tone: Equatable {
        case pro, trial, free
    }

    let title: String
    let tone: Tone
}

extension SettingsModel {
    func entries(
        in group: SettingsGroup? = nil, matching query: String = "", showsGuides: Bool,
        showsJourneyEntry: Bool, showsWebEntry: Bool = true
    ) -> [SettingsEntry] {
        SettingsEntry.allCases.filter { entry in
            switch entry {
            case .data: if data == nil { return false }
            case .web: if web == nil || !showsWebEntry { return false }
            case .guides: if !showsGuides { return false }
            case .journey: if !showsJourneyEntry { return false }
            default: break
            }
            return (group == nil || entry.group == group) && entry.matches(query)
        }
    }

    func planBadge(for entitlement: Entitlement, now: Date = .now) -> PlanBadge {
        switch entitlement {
        case .active: return PlanBadge(title: String(appLocalized: "Pro"), tone: .pro)
        case .trial(let expires):
            let calendar = Calendar.current
            let days =
                calendar.dateComponents(
                    [.day], from: calendar.startOfDay(for: now),
                    to: calendar.startOfDay(for: expires)
                ).day ?? 0
            return PlanBadge(
                title: String(appLocalized: "Trial · \(max(days, 0)) days left"), tone: .trial)
        case .none, .expired: return PlanBadge(title: String(appLocalized: "Free"), tone: .free)
        }
    }

    func proOfferTitle(for entitlement: Entitlement) -> String {
        if case .expired = entitlement { return String(appLocalized: "Come Back to Cashly Pro") }
        return String(appLocalized: "Try Cashly Pro")
    }

    func proValue(for entitlement: Entitlement) -> String {
        entitlement.isActive ? planBadge(for: entitlement).title : entitlement.title
    }

    var syncBadge: String {
        isSyncOn ? String(appLocalized: "iCloud") : String(appLocalized: "This Device")
    }

    var cloudValue: String {
        if needsRestart { return String(appLocalized: "Restart to Apply") }
        guard isSyncOn else { return String(appLocalized: "Off") }
        switch cloudAccount {
        case .noAccount, .restricted, .temporarilyUnavailable: return cloudAccount.title
        default: return String(appLocalized: "On")
        }
    }

    func profileName(_ user: User?) -> String {
        guard let name = user?.name, !name.isEmpty else { return "Cashly" }
        return name.capitalized
    }
}
