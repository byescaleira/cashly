import CashlyAnalytics
import CashlyDomain
import FeatureCore
import Foundation

extension InsightsModel {
    public struct Change: Equatable, Identifiable {
        public let id: String
        public let name: String
        public let difference: Double
        public let count: Int
        public let typicalCount: Int
        public let ticket: Double
        public let typicalTicket: Double
        public let isFrequency: Bool

        public var isUp: Bool { difference > 0 }

        public var badge: String {
            switch (isFrequency, isUp) {
            case (true, true): String(appLocalized: "More often")
            case (true, false): String(appLocalized: "Less often")
            case (false, true): String(appLocalized: "Pricier")
            case (false, false): String(appLocalized: "Cheaper")
            }
        }

        public var detail: String {
            isFrequency
                ? String(appLocalized: "Transactions: \(count), usually \(typicalCount)")
                : String(
                    appLocalized:
                        "Average amount: \(ticket.formatted(.appCurrency)), usually \(typicalTicket.formatted(.appCurrency))"
                )
        }

        public var amount: String {
            (isUp ? "+" : "−") + abs(difference).formatted(.appCurrency)
        }
    }

    public struct Merchant: Equatable, Identifiable {
        public let id: String
        public let name: String
        public let count: Int
        public let monthly: Double
        public let ticket: Double

        public var detail: String {
            String(appLocalized: "\(count) times · \(ticket.formatted(.appCurrency)) each")
        }

        public var amount: String {
            String(appLocalized: "\(monthly.formatted(.appCurrency))/month")
        }
    }

    public struct Small: Equatable {
        public let threshold: Double
        public let count: Int
        public let total: Double
        public let share: Double
        public let yearly: Double

        public var caption: String {
            String(
                appLocalized:
                    "\(count) purchases up to \(threshold.formatted(.appCurrency)) this month")
        }

        public var detail: String {
            String(
                appLocalized:
                    "\(share.formatted(.percent.precision(.fractionLength(0)).locale(.app))) of the month's spending. In a typical month, that adds up to \(yearly.formatted(.appCurrency)) a year."
            )
        }
    }

    public struct Weekdays: Equatable {
        public let name: String
        public let average: Double
        public let share: Double
        public let weeks: Int
        public let bars: [Bar]

        public var caption: String { String(appLocalized: "Your biggest day: \(name)") }

        public var detail: String {
            String(
                appLocalized:
                    "\(share.formatted(.percent.precision(.fractionLength(0)).locale(.app))) of what you spend without installments."
            )
        }

        public var footer: String {
            String(
                appLocalized:
                    "Average on each day of the week over the last \(weeks) weeks. Installment purchases are left out, so the days show your habits."
            )
        }
    }

    public var changes: [Change] {
        let hidden = Set(unusualFindings.map(\.subject)).union(expectedSubjects)
        let findings = results[SpendingDrivers.id]?.findings ?? []
        return findings.filter { !hidden.contains($0.subject) }.prefix(3).map { finding in
            let value = { (key: String) in finding.metric(key)?.value ?? 0 }
            return Change(
                id: finding.id, name: finding.label.capitalized,
                difference: Double(finding.impact) / 100, count: Int(value("count")),
                typicalCount: Int(value("typicalCount").rounded()), ticket: value("ticket"),
                typicalTicket: value("typicalTicket"),
                isFrequency: abs(value("frequency")) >= abs(value("ticketEffect")))
        }
    }

    public var merchants: [Merchant] {
        (results[TopMerchants.id]?.findings ?? []).prefix(3).map { finding in
            Merchant(
                id: finding.id, name: finding.label,
                count: Int(finding.metric("count")?.value ?? 0),
                monthly: finding.metric("monthly")?.value ?? 0,
                ticket: finding.metric("ticket")?.value ?? 0)
        }
    }

    public var small: Small? {
        guard let result = results[SmallPurchases.id],
            let threshold = result.metric("threshold")?.value,
            let total = result.metric("total")?.value
        else { return nil }
        return Small(
            threshold: threshold, count: Int(result.metric("count")?.value ?? 0), total: total,
            share: result.metric("share")?.value ?? 0,
            yearly: result.metric("yearly")?.value ?? 0)
    }

    public var weekdays: Weekdays? {
        guard let result = results[WeekdayPattern.id], !result.findings.isEmpty,
            let top = result.metric("weekday").map({ Int($0.value) }), (1...7).contains(top),
            let average = result.metric("average")?.value
        else { return nil }
        var calendar = CashlyCalendar.current
        calendar.locale = .app
        let short = calendar.shortStandaloneWeekdaySymbols
        let full = calendar.standaloneWeekdaySymbols
        return Weekdays(
            name: full[top - 1], average: average, share: result.metric("share")?.value ?? 0,
            weeks: Int((result.metric("days")?.value ?? 0) / 7),
            bars: result.series.compactMap { point in
                guard let weekday = Int(point.label), (1...7).contains(weekday) else { return nil }
                return Bar(
                    label: short[weekday - 1].capitalized(with: .app), value: point.value,
                    isCurrent: weekday == top)
            })
    }
}
