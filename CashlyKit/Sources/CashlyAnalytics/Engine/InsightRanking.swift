import CashlyDomain
import Foundation

public struct InsightFeedback: Hashable, Sendable, Codable {
    public private(set) var expected: Set<String>
    public private(set) var dismissed: Set<String>

    public init(expected: Set<String> = [], dismissed: Set<String> = []) {
        self.expected = expected
        self.dismissed = dismissed
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expected = try container.decodeIfPresent(Set<String>.self, forKey: .expected) ?? []
        dismissed = try container.decodeIfPresent(Set<String>.self, forKey: .dismissed) ?? []
    }

    public func isDismissed(_ finding: Finding) -> Bool {
        dismissed.contains(finding.id)
    }

    public mutating func dismiss(_ finding: Finding) {
        dismissed.insert(finding.id)
    }

    public func isExpected(_ finding: Finding, in month: YearMonth) -> Bool {
        expected.contains(Self.key(finding.id, month))
    }

    public mutating func markExpected(_ finding: Finding, in month: YearMonth) {
        expected = expected.filter { Self.month(of: $0) >= month.rawValue }
        expected.insert(Self.key(finding.id, month))
    }

    private static func key(_ id: String, _ month: YearMonth) -> String {
        "\(month.rawValue)|\(id)"
    }

    private static func month(of key: String) -> Int {
        Int(key.prefix { $0 != "|" }) ?? 0
    }
}

public enum InsightRanking {
    public static func rank(
        _ findings: [Finding], feedback: InsightFeedback = InsightFeedback(), in month: YearMonth
    ) -> [Finding] {
        findings
            .filter {
                $0.impact > 0 && !feedback.isExpected($0, in: month) && !feedback.isDismissed($0)
            }
            .sorted {
                let left = score($0)
                let right = score($1)
                return left == right ? $0.id < $1.id : left > right
            }
    }

    static func score(_ finding: Finding) -> Double {
        Double(finding.impact) * weight(finding.confidence)
    }

    static func weight(_ confidence: Provenance.Confidence) -> Double {
        switch confidence {
        case .certain: 1
        case .high: 0.9
        case .medium: 0.7
        case .low: 0.4
        }
    }
}
