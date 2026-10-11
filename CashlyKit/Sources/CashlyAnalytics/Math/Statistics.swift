import Foundation

public enum Statistics {
    public static func mean(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    public static func quantile(_ values: [Double], _ p: Double) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let position = min(max(p, 0), 1) * Double(sorted.count - 1)
        let lower = Int(position.rounded(.down))
        let upper = Int(position.rounded(.up))
        let weight = position - Double(lower)
        return sorted[lower] + (sorted[upper] - sorted[lower]) * weight
    }

    public static func median(_ values: [Double]) -> Double? {
        quantile(values, 0.5)
    }

    public static func medianAbsoluteDeviation(_ values: [Double]) -> Double? {
        guard let median = median(values) else { return nil }
        return Statistics.median(values.map { abs($0 - median) })
    }

    public static func robustZScore(_ value: Double, in values: [Double]) -> Double? {
        guard let median = median(values), let mad = medianAbsoluteDeviation(values), mad > 0
        else { return nil }
        return 0.6745 * (value - median) / mad
    }
}
