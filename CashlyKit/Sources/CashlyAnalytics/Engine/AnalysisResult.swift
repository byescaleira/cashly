import CashlyDomain
import Foundation

public struct AnalysisID: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        rawValue = value
    }
}

public struct Provenance: Hashable, Sendable, Codable {
    public enum Confidence: String, Sendable, Codable {
        case certain, high, medium, low
    }

    public let method: String
    public let version: Int
    public let revision: String
    public let confidence: Confidence
    public let evidence: [String]
}

public struct Metric: Hashable, Sendable, Codable {
    public enum Unit: String, Sendable, Codable {
        case money, ratio, days, count
    }

    public let key: String
    public let label: String
    public let value: Double
    public let unit: Unit

    public static func money(_ key: String, _ label: String, minorUnits: Int64) -> Metric {
        Metric(key: key, label: label, value: Double(minorUnits) / 100, unit: .money)
    }
}

public struct SeriesPoint: Hashable, Sendable, Codable {
    public let label: String
    public let value: Double
    public let reference: Double?

    public init(label: String, value: Double, reference: Double? = nil) {
        self.label = label
        self.value = value
        self.reference = reference
    }
}

public struct AnalysisResult: Sendable, Codable, Identifiable {
    public let id: AnalysisID
    public let title: String
    public let summary: String
    public let metrics: [Metric]
    public let series: [SeriesPoint]
    public let provenance: Provenance

    public func metric(_ key: String) -> Metric? {
        metrics.first { $0.key == key }
    }
}
