import CashlyGame

public struct JourneyBaseline: Equatable, Sendable {
    public let level: Int
    public let achievements: Set<Achievement>

    public init(level: Int, achievements: Set<Achievement>) {
        self.level = level
        self.achievements = achievements
    }

    init?(_ dictionary: [String: Any]?) {
        guard let dictionary, let level = dictionary[Field.level] as? Int else { return nil }
        let names = dictionary[Field.achievements] as? [String] ?? []
        self.init(level: level, achievements: Set(names.compactMap(Achievement.init)))
    }

    var dictionary: [String: Any] {
        [Field.level: level, Field.achievements: achievements.map(\.rawValue).sorted()]
    }

    private enum Field {
        static let level = "level"
        static let achievements = "achievements"
    }
}
