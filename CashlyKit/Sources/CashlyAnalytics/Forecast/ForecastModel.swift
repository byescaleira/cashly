import Foundation

public enum ForecastModel: String, CaseIterable, Sendable, Codable {
    case naive, seasonalNaive, median, smoothing, croston

    public func predict(_ history: [Double], horizon: Int = 1) -> Double? {
        switch self {
        case .naive:
            return history.last
        case .seasonalNaive:
            let index = history.count - 12 + horizon - 1
            return index >= 0 && index < history.count ? history[index] : nil
        case .median:
            return Statistics.median(Array(history.suffix(6)))
        case .smoothing:
            guard let first = history.first else { return nil }
            return history.dropFirst().reduce(first) { 0.3 * $1 + 0.7 * $0 }
        case .croston:
            return Self.croston(history)
        }
    }

    static func croston(_ history: [Double], alpha: Double = 0.1) -> Double? {
        let demands = history.enumerated().filter { $0.element > 0 }
        guard demands.count >= 2, demands.count * 10 <= history.count * 7 else { return nil }
        var size = demands[0].element
        var interval = Double(demands[0].offset + 1)
        for (previous, current) in zip(demands, demands.dropFirst()) {
            size = alpha * current.element + (1 - alpha) * size
            interval = alpha * Double(current.offset - previous.offset) + (1 - alpha) * interval
        }
        return size / interval
    }
}
