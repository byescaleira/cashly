import CashlyAnalytics
import CashlyDomain
import FeatureCore
import Foundation

extension InsightsModel {
    public struct NextMonth: Equatable {
        public let total: Double
        public let low: Double
        public let high: Double
        public let committed: Double

        public init(total: Double, low: Double, high: Double, committed: Double) {
            self.total = total
            self.low = low
            self.high = high
            self.committed = committed
        }

        public var amount: String { total.formatted(.appCurrency) }

        public var range: String? {
            guard high > low else { return nil }
            let low = low.formatted(.appCurrency)
            let high = high.formatted(.appCurrency)
            return committed > 0
                ? String(appLocalized: "Between \(low) and \(high), counting installments")
                : String(appLocalized: "Between \(low) and \(high)")
        }
    }

    public var nextMonth: NextMonth? {
        guard let result = results[NextMonthForecast.id],
            let total = result.metric("total")?.value
        else { return nil }
        return NextMonth(
            total: total, low: result.metric("low")?.value ?? total,
            high: result.metric("high")?.value ?? total,
            committed: result.metric("committed")?.value ?? 0)
    }

    public var futureFooter: String {
        let ranged = nextMonth?.range != nil
        switch (nextMonth != nil, commitments != nil, !endings.isEmpty) {
        case (true, true, true):
            return ranged
                ? String(
                    appLocalized:
                        "Based on your past months plus what's already committed; most months fall within the range. The months at the end show when installments finish and how much stops going out."
                )
                : String(
                    appLocalized:
                        "Based on your past months plus what's already committed. The months at the end show when installments finish and how much stops going out."
                )
        case (true, true, false):
            return ranged
                ? String(
                    appLocalized:
                        "Based on your past months plus what's already committed; most months fall within the range."
                )
                : String(appLocalized: "Based on your past months plus what's already committed.")
        case (true, false, _):
            return ranged
                ? String(
                    appLocalized: "Based on your past months; most months fall within the range.")
                : String(appLocalized: "Based on your past months.")
        case (false, _, true):
            return String(
                appLocalized:
                    "Installments and future bills you've already recorded. The months at the end show when installments finish and how much stops going out."
            )
        case (false, _, false):
            return String(appLocalized: "Installments and future bills you've already recorded.")
        }
    }
}

extension Double {
    func nilIfOutside(_ range: ClosedRange<Double>) -> Double? {
        range.contains(self) ? self : nil
    }
}
