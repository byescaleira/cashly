import CashlyAnalytics
import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class InsightsModel {
    public struct Key: Hashable {
        let userID: String?
        let generation: Int
        let day: Date
    }

    public struct Bar: Equatable, Identifiable {
        public let label: String
        public let value: Double
        public let isCurrent: Bool
        public var id: String { label }
    }

    public struct Outlook: Equatable {
        public let spent: Double
        public let remaining: Double
        public let projected: Double
        public let budgeted: Double?
        public let daily: Double?
        public let daysLeft: Int?
        public let isUncertain: Bool

        public var gap: Double? { budgeted.map { projected - $0 } }
        public var scale: Double { max(projected, budgeted ?? 0, 1) }
    }

    public struct History: Equatable {
        public let difference: Double
        public let day: Int
        public let months: Int
        public let bars: [Bar]
    }

    public struct Unusual: Equatable, Identifiable {
        public let id: String
        public let name: String
        public let current: Double
        public let typical: Double

        public var badge: String {
            guard typical > 0 else { return String(appLocalized: "New this month") }
            let times = (current / typical).formatted(
                .number.precision(.fractionLength(1)).locale(.app))
            return String(appLocalized: "\(times)× usual")
        }

        public var reference: String {
            typical > 0
                ? String(appLocalized: "Usually \(typical.formatted(.appCurrency))")
                : String(appLocalized: "No spending in other months")
        }
    }

    public struct Commitments: Equatable {
        public let total: Double
        public let nextMonth: Double
        public let bars: [Bar]
    }

    private var stored: [AnalysisID: AnalysisResult] = [:]
    private var feedback = InsightFeedback()
    private var month = YearMonth(.now)
    private var day = Calendar.current.startOfDay(for: .now)
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let engine = AnalysisEngine()
    @ObservationIgnored private let store: InsightFeedbackStore

    public init(session: SessionModel, defaults: UserDefaults = .standard) {
        self.session = session
        store = InsightFeedbackStore(defaults: defaults)
    }

    public var key: Key {
        Key(userID: session.user?.id, generation: session.generation, day: day)
    }

    private var results: [AnalysisID: AnalysisResult] {
        session.filter.isCustomized ? [:] : stored
    }

    private var findings: [Finding] {
        InsightRanking.rank(results.values.flatMap(\.findings), feedback: feedback, in: month)
    }

    public func checkDay() {
        let today = Calendar.current.startOfDay(for: .now)
        if today != day { day = today }
    }

    public func load() async {
        guard let userID = session.user?.id else {
            stored = [:]
            return
        }
        feedback = store.feedback(for: userID)
        do {
            let ledger = try await RepositoriesLedgerSource(repositories: session.repositories)
                .ledger(today: .now)
            let all = await engine.runAll(on: ledger)
            guard !Task.isCancelled else { return }
            month = ledger.currentMonth
            stored = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        } catch {
            stored = [:]
        }
    }

    public var outlook: Outlook? {
        guard let pace = results[MonthPace.id],
            let spent = pace.metric("spent")?.value,
            let projected = pace.metric("projected")?.value
        else { return nil }
        let remaining = pace.metric("remaining")?.value ?? max(projected - spent, 0)
        let allowance = results[DailyAllowance.id]
        return Outlook(
            spent: spent, remaining: remaining, projected: projected,
            budgeted: pace.metric("budgeted")?.value,
            daily: allowance?.metric("daily")?.value,
            daysLeft: allowance?.metric("daysLeft").map { Int($0.value) },
            isUncertain: pace.provenance.confidence == .low)
    }

    public var history: History? {
        guard let comparison = results[SamePointComparison.id],
            let difference = comparison.metric("difference")?.value,
            let day = comparison.metric("day")?.value
        else { return nil }
        let points = comparison.series
        return History(
            difference: difference, day: Int(day), months: max(points.count - 1, 0),
            bars: points.enumerated().map {
                Bar(label: $1.label, value: $1.value, isCurrent: $0 == points.count - 1)
            })
    }

    public var unusual: [Unusual] {
        findings.filter { $0.analysisID == UnusualCategories.id }.prefix(3).map {
            Unusual(
                id: $0.id, name: $0.label.capitalized, current: $0.metric("current")?.value ?? 0,
                typical: $0.metric("typical")?.value ?? 0)
        }
    }

    public func markExpected(_ item: Unusual) {
        guard let finding = findings.first(where: { $0.id == item.id }),
            let userID = session.user?.id
        else { return }
        feedback.markExpected(finding, in: month)
        store.save(feedback, for: userID)
    }

    public var commitments: Commitments? {
        guard let result = results[InstallmentCommitments.id],
            let total = result.metric("total")?.value
        else { return nil }
        return Commitments(
            total: total, nextMonth: result.metric("nextMonth")?.value ?? 0,
            bars: result.series.enumerated().map {
                Bar(label: $1.label, value: $1.value, isCurrent: $0 == 0)
            })
    }
}
