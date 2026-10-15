import CashlyDomain
import CashlyGame
import FeatureCore
import Foundation
import Observation

struct AboutFigure: Identifiable, Equatable {
    enum Kind: Equatable {
        case history, transactions, days, level, budgets

        var symbol: String {
            switch self {
            case .history: "calendar"
            case .transactions: "list.bullet.rectangle"
            case .days: "checkmark.seal"
            case .level: "trophy"
            case .budgets: "chart.bar"
            }
        }
    }

    let kind: Kind
    let value: String
    let numeric: Double
    let caption: String
    let detail: String

    var id: Kind { kind }
}

enum AboutPlan: Equatable {
    case free, trial, pro

    init(_ entitlement: Entitlement) {
        switch entitlement {
        case .none, .expired: self = .free
        case .trial: self = .trial
        case .active: self = .pro
        }
    }

    var title: String {
        switch self {
        case .free: String(appLocalized: "Free")
        case .trial: String(appLocalized: "Pro Trial")
        case .pro: String(appLocalized: "Cashly Pro")
        }
    }

    var isPro: Bool { self != .free }
}

@MainActor @Observable
final class AboutModel {
    private(set) var usage: AboutUsage?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let now: () -> Date

    init(session: SessionModel, now: @escaping () -> Date = { .now }) {
        self.session = session
        self.now = now
    }

    let lottieURL = URL(string: "https://github.com/airbnb/lottie-ios")

    let illustrationsURL = URL(string: "https://ipaslogo.com")

    var hasLoaded: Bool { usage != nil }

    var isEmpty: Bool { usage?.transactions == 0 }

    var shareMessage: String { String(appLocalized: "I plan my month with Cashly.") }

    func plan(for entitlement: Entitlement) -> AboutPlan { AboutPlan(entitlement) }

    func load() async {
        guard session.user != nil else {
            usage = .empty
            return
        }
        let source = RepositoriesGameSource(
            repositories: session.repositories, guideCount: Guide.allCases.count)
        guard let snapshot = try? await source.snapshot(today: now()) else { return }
        usage = AboutUsage(snapshot: snapshot, progress: GameEngine.progress(snapshot))
    }

    func figures(showingJourney: Bool) -> [AboutFigure] {
        let usage = usage ?? .empty
        let last: AboutFigure =
            showingJourney
            ? AboutFigure(
                kind: .level, value: String(appLocalized: "Level \(usage.level)"),
                numeric: Double(usage.level), caption: String(appLocalized: "Journey"),
                detail: String(appLocalized: "\(number(usage.xp)) XP"))
            : AboutFigure(
                kind: .budgets, value: number(usage.budgets), numeric: Double(usage.budgets),
                caption: String(appLocalized: "Budgets"),
                detail: thisMonth(usage.budgetsThisMonth))
        return [
            AboutFigure(
                kind: .history, value: since(usage.firstRecord),
                numeric: usage.firstRecord?.timeIntervalSinceReferenceDate ?? 0,
                caption: String(appLocalized: "First record"),
                detail: history(months: usage.monthsOfHistory)),
            AboutFigure(
                kind: .transactions, value: number(usage.transactions),
                numeric: Double(usage.transactions), caption: String(appLocalized: "Transactions"),
                detail: thisMonth(usage.transactionsThisMonth)),
            AboutFigure(
                kind: .days, value: number(usage.activeDays), numeric: Double(usage.activeDays),
                caption: String(appLocalized: "Active days"),
                detail: thisMonth(usage.activeDaysThisMonth)),
            last,
        ]
    }

    func history(months: Int) -> String {
        if months >= 24 {
            String(appLocalized: "\(months / 12) years of records")
        } else if months > 0 {
            String(appLocalized: "\(months) months of records")
        } else {
            String(appLocalized: "Started this month")
        }
    }

    private func since(_ date: Date?) -> String {
        (date ?? now()).formatted(Date.FormatStyle(locale: .app).month(.abbreviated).year())
    }

    private func number(_ value: Int) -> String {
        value.formatted(.number.locale(.app))
    }

    private func thisMonth(_ count: Int) -> String {
        String(appLocalized: "\(number(count)) this month")
    }
}

extension SettingsModel {
    var syncStatus: String {
        isSyncOn ? String(appLocalized: "On") : String(appLocalized: "Off")
    }
}
