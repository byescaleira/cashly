import Foundation
import SwiftData

@Model
public class MerchantMemoryEntity {
    #Index<MerchantMemoryEntity>([\.ownerID, \.key])
    public var id: String = ""
    public var ownerID: String = ""
    public var key: String = ""
    public var categoryID: String = ""
    public var summary: String = ""
    public var tagIDs: [String] = []
    public var count: Int = 0
    public var updatedAt: TimeInterval = 0

    public init(id: String, ownerID: String, key: String) {
        self.id = id
        self.ownerID = ownerID
        self.key = key
    }
}
