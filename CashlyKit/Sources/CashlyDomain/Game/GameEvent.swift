import Foundation

public struct GameEvent: Identifiable, Hashable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case transactionRecorded, noSpendDay, guideCompleted, challengeStarted, challengeAbandoned
        case freezesCredited, streakRestored, rerollsCredited, backupCreated, spreadsheetImported
    }

    public let id: String
    public let kind: Kind
    public let date: Date
    public let value: String
    public let count: Int

    public init(
        id: String = UUID().uuidString, kind: Kind, date: Date = .now, value: String = "",
        count: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.date = date
        self.value = value
        self.count = count
    }
}
