import CashlyDomain
import Foundation
import SwiftData

@Model
public class ParticipantEntity {
    #Index<ParticipantEntity>([\.transaction, \.id])
    public var id: String = ""
    public var user: String = ""
    public var name: String = ""
    public var photo: String = ""
    public var splitMode: Int = 0
    public var splitValue: Double = 0
    public var allocatedMinorUnits: Int64?
    public var status: Int = 0
    public var transaction: String = ""

    public init(
        id: String,
        user: String,
        name: String,
        photo: String,
        splitMode: Int,
        splitValue: Double,
        status: Int,
        transaction: String
    ) {
        self.id = id
        self.user = user
        self.name = name
        self.photo = photo
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.status = status
        self.transaction = transaction
    }
}
