import CashlyAnalytics
import Foundation

public struct InsightFeedbackStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func feedback(for userID: String) -> InsightFeedback {
        defaults.data(forKey: Self.key(userID))
            .flatMap { try? JSONDecoder().decode(InsightFeedback.self, from: $0) }
            ?? InsightFeedback()
    }

    public func save(_ feedback: InsightFeedback, for userID: String) {
        guard let data = try? JSONEncoder().encode(feedback) else { return }
        defaults.set(data, forKey: Self.key(userID))
    }

    public func erase(_ userIDs: [String]) {
        for userID in userIDs { defaults.removeObject(forKey: Self.key(userID)) }
    }

    private static func key(_ userID: String) -> String { "cashly.insights.feedback.\(userID)" }
}
