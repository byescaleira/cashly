public struct GameLevel: Equatable, Sendable {
    public static let maximum = 50
    public static let rankLength = 5
    public static var ranks: Int { maximum / rankLength }

    public let number: Int
    public let xpIntoLevel: Int
    public let xpForNextLevel: Int

    public init(xp: Int) {
        var number = 1
        while number < Self.maximum && Self.threshold(number + 1) <= xp { number += 1 }
        self.number = number
        xpIntoLevel = xp - Self.threshold(number)
        xpForNextLevel =
            number == Self.maximum ? 0 : Self.threshold(number + 1) - Self.threshold(number)
    }

    public static func threshold(_ level: Int) -> Int { 50 * (level - 1) * level }

    public var rank: Int { (number - 1) / Self.rankLength }

    public var nextRankLevel: Int? {
        rank + 1 < Self.ranks ? (rank + 1) * Self.rankLength + 1 : nil
    }

    public var progress: Double {
        xpForNextLevel == 0 ? 1 : Double(xpIntoLevel) / Double(xpForNextLevel)
    }

    public var rankProgress: Double {
        let steps = Double(Self.rankLength)
        return Double(rank) + (Double((number - 1) % Self.rankLength) + progress) / steps
    }
}
