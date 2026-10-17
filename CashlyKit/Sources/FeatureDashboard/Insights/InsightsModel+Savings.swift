import CashlyAnalytics
import CashlyDomain
import FeatureCore
import Foundation

extension InsightsModel {
    public struct Recurring: Equatable, Identifiable {
        public let id: String
        public let name: String
        public let monthly: Double
        public let months: Int
        public let next: Date

        public var amount: String {
            String(appLocalized: "\(monthly.formatted(.appCurrency))/month")
        }

        public var detail: String {
            String(
                appLocalized:
                    "In \(months) of the last 6 months · next around \(next.formatted(.dateTime.day().month(.abbreviated).locale(.app)))"
            )
        }
    }

    public struct Recurrences: Equatable {
        public let items: [Recurring]
        public let count: Int
        public let yearly: Double

        public var caption: String {
            String(appLocalized: "a year in \(count) charges that repeat every month")
        }
    }

    public struct BudgetIdea: Equatable, Identifiable {
        public let id: String
        public let categoryID: String
        public let name: String
        public let suggested: Double
        public let month: YearMonth

        public var route: Route {
            .addBudget(id: nil, categoryID: categoryID, date: month.startDate, amount: suggested)
        }

        public var detail: String {
            String(
                appLocalized: "No budget this month · usually \(suggested.formatted(.appCurrency))")
        }
    }

    public struct Ending: Equatable, Identifiable {
        public let id: String
        public let month: YearMonth
        public let freed: Double

        public var title: String {
            String(
                appLocalized:
                    "Free from \(month.startDate.formatted(.dateTime.month(.wide).year().locale(.app)))"
            )
        }

        public var amount: String {
            String(appLocalized: "\(freed.formatted(.appCurrency))/month")
        }
    }

    public var recurrences: Recurrences? {
        guard let result = results[RecurringCharges.id] else { return nil }
        let calendar = CashlyCalendar.current
        let visible = findings.filter { $0.analysisID == RecurringCharges.id }
        guard !visible.isEmpty else { return nil }
        return Recurrences(
            items: visible.prefix(5).map {
                finding in
                Recurring(
                    id: finding.id, name: finding.label,
                    monthly: finding.metric("monthly")?.value ?? 0,
                    months: min(Int(finding.metric("months")?.value ?? 0), 6),
                    next: calendar.date(
                        byAdding: .day, value: Int(finding.metric("nextIn")?.value ?? 0), to: day)
                        ?? day)
            }, count: result.findings.count, yearly: result.metric("yearly")?.value ?? 0)
    }

    public var budgetIdeas: [BudgetIdea] {
        findings.filter { $0.analysisID == SuggestedBudgets.id }.prefix(3).map { finding in
            BudgetIdea(
                id: finding.id, categoryID: finding.subject, name: finding.label.capitalized,
                suggested: finding.metric("suggested")?.value ?? 0, month: month)
        }
    }

    public var endings: [Ending] {
        (results[EndingInstallments.id]?.findings ?? []).compactMap { finding in
            guard let raw = finding.metric("month")?.value,
                let month = YearMonth(rawValue: Int(raw))
            else { return nil }
            return Ending(id: finding.id, month: month, freed: Double(finding.impact) / 100)
        }
    }

    public func keep(_ item: Recurring) {
        dismiss(item.id)
    }

    public func hide(_ item: BudgetIdea) {
        dismiss(item.id)
    }
}
