import Foundation
import SwiftData

/// Frozen field layout from commit 510d6be. Never add fields to this schema.
public enum CashlySchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [
            BudgetEntity.self, CategoryEntity.self, ParticipantEntity.self, TagEntity.self,
            TransactionEntity.self, UserEntity.self,
        ]
    }
    @Model
    public class BudgetEntity {
        public var id: String = ""
        public var amount: Double = 0
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
    public class CategoryEntity {
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
    public class ParticipantEntity {
        public var id: String = ""
        public var user: String = ""
        public var name: String = ""
        public var photo: String = ""
        public var splitMode: Int = 0
        public var splitValue: Double = 0
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
    public class TagEntity {
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
        public var id: String = ""
        public var participants: [String] = []
        public var budget: String = ""
        public var amount: Double = 0
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
}
