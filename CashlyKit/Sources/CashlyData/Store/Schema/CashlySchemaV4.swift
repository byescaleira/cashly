import CashlyDomain
import Foundation
import SwiftData

public enum CashlySchemaV4: VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(4, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [
            UserEntity.self, CategoryEntity.self, BudgetEntity.self, TagEntity.self,
            TransactionEntity.self, ParticipantEntity.self, GameEventEntity.self,
        ]
    }

    @Model
    public class UserEntity {
        public var id: String = ""
        public var name: String = ""
        public var photo: String = ""

        public init(
            id: String,
            name: String,
            photo: String
        ) {
            self.id = id
            self.name = name
            self.photo = photo
        }
    }

    @Model
    public class CategoryEntity {
        #Index<CategoryEntity>([\.user, \.id])
        public var id: String = ""
        public var name: String = ""
        public var user: String = ""
        public var color: String = ""
        public var icon: String = ""

        public init(
            id: String,
            user: String,
            name: String,
            color: String,
            icon: String
        ) {
            self.id = id
            self.user = user
            self.name = name
            self.color = color
            self.icon = icon
        }
    }

    @Model
    public class BudgetEntity {
        #Index<BudgetEntity>([\.ownerID, \.date, \.category])
        public var id: String = ""
        public var amount: Double = 0
        public var amountSource: Double = -1
        public var amountMinorUnits: Int64?
        public var currencyCode: String = "BRL"
        public var isConflicted: Bool = false
        public var ownerID: String = ""
        public var mergedIntoID: String = ""
        public var resolutionToken: String = ""
        public var resolutionTimestamp: Double = 0
        public var resolvedTargetID: String = ""
        public var category: String = ""
        public var date: Int = 0
        public var summary: String = ""

        public init(
            id: String,
            amount: Double,
            category: String,
            date: Int,
            summary: String
        ) {
            self.id = id
            self.amount = amount
            self.category = category
            self.date = date
            self.summary = summary
        }
    }

    @Model
    public class TagEntity {
        #Index<TagEntity>([\.user, \.id])
        public var id: String = ""
        public var name: String = ""
        public var user: String = ""
        public var color: String = ""
        public var icon: String = ""

        public init(
            id: String,
            user: String,
            name: String,
            color: String,
            icon: String
        ) {
            self.id = id
            self.user = user
            self.name = name
            self.color = color
            self.icon = icon
        }
    }

    @Model
    public class TransactionEntity {
        #Index<TransactionEntity>(
            [\.ownerID, \.date, \.id], [\.ownerID, \.id], [\.ownerID, \.categoryID, \.date],
            [\.ownerID, \.kind, \.date], [\.ownerID, \.startMonthIndex, \.endMonthIndex])
        public var id: String = ""
        public var participants: [String] = []
        public var budget: String = ""
        public var categoryID: String = ""
        public var kind: Int = 0
        public var amount: Double = 0
        public var dateSource: Double = 0
        public var paymentsPlanSource: Int?
        public var amountSource: Double = -1
        public var amountMinorUnits: Int64?
        public var ownerMinorUnits: Int64?
        public var currencyCode: String = "BRL"
        public var ownerID: String = ""
        public var tagIDs: [String] = []
        public var tagsMigrated: Bool = false
        public var startMonthIndex: Int = 0
        public var endMonthIndex: Int = 0
        public var contentRevision: String = ""
        public var date: TimeInterval = 0
        public var summary: String = ""
        public var status: Int = 0
        public var splitMode: Int?
        public var splitValue: Double?
        public var paymentsPlan: Int?

        public init(
            id: String,
            participants: [String],
            budget: String,
            amount: Double,
            date: TimeInterval,
            summary: String,
            status: Int,
            splitMode: Int? = nil,
            splitValue: Double? = nil,
            paymentsPlan: Int? = nil
        ) {
            self.id = id
            self.participants = participants
            self.budget = budget
            self.amount = amount
            self.date = date
            self.summary = summary
            self.status = status
            self.splitMode = splitMode
            self.splitValue = splitValue
            self.paymentsPlan = paymentsPlan
        }
    }

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
}
