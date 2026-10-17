import Foundation

public struct Forecast: Hashable, Sendable, Codable {
    public let model: ForecastModel
    public let value: Double
    public let low: Double
    public let high: Double
    public let meanAbsoluteError: Double
    public let scaledError: Double?
    public let residuals: Int
}

public enum Forecaster {
    public static func forecast(
        _ history: [Double], horizon: Int = 1, models: [ForecastModel] = ForecastModel.allCases,
        origins: Int = 12
    ) -> Forecast? {
        let first = max(3, history.count - horizon + 1 - origins)
        let last = history.count - horizon
        guard last >= first else { return nil }
        let ends = Array(first...last)
        guard ends.count >= 3 else { return nil }
        let candidates = models.compactMap { model -> (ForecastModel, [Double])? in
            let residuals = ends.compactMap { end -> Double? in
                model.predict(Array(history[..<end]), horizon: horizon).map {
                    history[end + horizon - 1] - $0
                }
            }
            return residuals.count == ends.count ? (model, residuals) : nil
        }
        guard
            let best = candidates.min(by: { meanAbsolute($0.1) < meanAbsolute($1.1) }),
            let value = best.0.predict(history, horizon: horizon)
        else { return nil }
        let point = max(value, 0)
        let error = meanAbsolute(best.1)
        let (below, above) = spread(best.1, error: error)
        return Forecast(
            model: best.0, value: point, low: max(point - below, 0), high: point + above,
            meanAbsoluteError: error, scaledError: scale(history).map { error / $0 },
            residuals: best.1.count)
    }

    static func spread(_ residuals: [Double], error: Double) -> (below: Double, above: Double) {
        let normal = 1.28 * 1.25 * error
        guard residuals.count >= 10 else { return (normal, normal) }
        return (
            max(-(Statistics.quantile(residuals, 0.1) ?? 0), 0),
            max(Statistics.quantile(residuals, 0.9) ?? 0, 0)
        )
    }

    static func meanAbsolute(_ values: [Double]) -> Double {
        Statistics.mean(values.map(abs)) ?? .infinity
    }

    static func scale(_ history: [Double]) -> Double? {
        let steps = zip(history, history.dropFirst()).map { abs($1 - $0) }
        guard let mean = Statistics.mean(steps), mean > 0 else { return nil }
        return mean
    }
}
