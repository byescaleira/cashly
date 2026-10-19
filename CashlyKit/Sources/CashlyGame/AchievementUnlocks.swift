import Foundation

public enum AchievementUnlocks {
    public static func key(for userID: String) -> String {
        "cashly.journey.unlocked." + userID
    }

    public static func dates(_ stored: [String: Double]) -> [Achievement: Date] {
        Dictionary(
            uniqueKeysWithValues: stored.compactMap { raw, time in
                Achievement(rawValue: raw).map { ($0, Date(timeIntervalSince1970: time)) }
            })
    }

    public static func dates(for userID: String, in defaults: UserDefaults) -> [Achievement: Date] {
        dates(defaults.dictionary(forKey: key(for: userID)) as? [String: Double] ?? [:])
    }
}
