import Foundation
import SwiftData

@Model
public class GameEventEntity {
    #Index<GameEventEntity>([\.ownerID, \.date], [\.ownerID, \.id])
    public var id: String = ""
    public var ownerID: String = ""
    public var kind: String = ""
    public var date: TimeInterval = 0
    public var value: String = ""
    public var count: Int = 0

    public init(
        id: String, ownerID: String, kind: String, date: TimeInterval, value: String, count: Int
    ) {
        self.id = id
        self.ownerID = ownerID
        self.kind = kind
        self.date = date
        self.value = value
        self.count = count
    }
}
