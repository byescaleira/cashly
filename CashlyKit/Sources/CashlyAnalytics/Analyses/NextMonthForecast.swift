import CashlyDomain
import Foundation

public struct NextMonthForecast: Analysis {
    public static let id: AnalysisID = "next-month-forecast"
    public static let title = "Next month forecast"
    public static let detail =
        "What next month should cost: purchases without installments and first installments of new plans, each forecast by the model that best predicted your past months two months ahead, plus installments already committed."
    public static let version = 3

    public init() {}

    public func run(_ ledger: LedgerSnapshot) -> AnalysisResult? {
        let month = ledger.currentMonth
        let next = month.adding(months: 1)
        guard let first = ledger.postings.filter(\.isExpense).map(\.month).min() else {
            return nil
        }
        let months = MonthlySeries(values: [:]).months(
            from: max(first, month.adding(months: -24)), to: month.adding(months: -1))
        guard months.count >= 7 else { return nil }
        let oneOff = MonthlySeries(ledger.postings) {
            $0.isExpense && $0.installments <= 1 ? $0.minorUnits : nil
        }
        let newPlans = MonthlySeries(ledger.postings) {
            $0.isExpense && $0.installments > 1 && $0.installment == 1 ? $0.minorUnits : nil
        }
        guard
            let purchases = Forecaster.forecast(months.map { Double(oneOff[$0]) }, horizon: 2)
        else { return nil }
        let plans = Forecaster.forecast(months.map { Double(newPlans[$0]) }, horizon: 2)
        let upcoming = ledger.postings(in: next).filter(\.isExpense)
        let committed = upcoming.filter { $0.installments > 1 }.reduce(0) { $0 + $1.minorUnits }
        let scheduled = upcoming.filter { $0.installments <= 1 }.reduce(0) { $0 + $1.minorUnits }
        let variable = max(Int64(purchases.value.rounded()), scheduled)
        let fresh = Int64((plans?.value ?? 0).rounded())
        let total = variable + fresh + committed
        let low =
            max(Int64(purchases.low.rounded()), scheduled) + Int64((plans?.low ?? 0).rounded())
            + committed
        let high =
            max(Int64(purchases.high.rounded()), scheduled) + Int64((plans?.high ?? 0).rounded())
            + committed
        var metrics: [Metric] = [
            .money("total", "Forecast", minorUnits: total),
            .money("low", "Low", minorUnits: low),
            .money("high", "High", minorUnits: high),
            .money("committed", "Installments already committed", minorUnits: committed),
            .money("variable", "Purchases without installments", minorUnits: variable),
            .money("newPlans", "First installments of new plans", minorUnits: fresh),
            Metric(key: "months", label: "Months", value: Double(months.count), unit: .count),
        ]
        if let error = purchases.scaledError {
            metrics.append(Metric(key: "error", label: "Scaled error", value: error, unit: .ratio))
        }
        return result(
            ledger,
            summary:
                "Next month should cost about \(Formatting.money(total)), between \(Formatting.money(low)) and \(Formatting.money(high)).",
            metrics: metrics,
            method:
                "Purchases without installments forecast with the \(purchases.model.rawValue) model and first installments of new plans with the \((plans?.model ?? .naive).rawValue) model, each chosen by the lowest mean absolute error predicting past months two months ahead; the range comes from those errors (10th to 90th percentile with ten or more, otherwise about 80% of a normal spread); installments already committed are added",
            confidence: confidence(purchases))
    }

    private func confidence(_ forecast: Forecast) -> Provenance.Confidence {
        if forecast.meanAbsoluteError == 0 { return .high }
        guard let error = forecast.scaledError, forecast.residuals >= 6 else { return .low }
        return error < 1 ? .high : error < 1.5 ? .medium : .low
    }
}
