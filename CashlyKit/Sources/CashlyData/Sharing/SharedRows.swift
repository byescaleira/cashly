import Foundation

struct ProfileRow: Codable, Equatable {
    var id: String
    var name: String
    var photo: String

    init(_ entity: UserEntity) {
        id = entity.id
        name = entity.name
        photo = entity.photo
    }

    func apply(to entity: UserEntity) {
        entity.name = name
        entity.photo = photo
    }
}

struct LabelRow: Codable, Equatable {
    var id: String
    var user: String
    var name: String
    var color: String
    var icon: String

    init(_ entity: CategoryEntity) {
        id = entity.id
        user = entity.user
        name = entity.name
        color = entity.color
        icon = entity.icon
    }

    init(_ entity: TagEntity) {
        id = entity.id
        user = entity.user
        name = entity.name
        color = entity.color
        icon = entity.icon
    }

    func apply(to entity: CategoryEntity) {
        entity.user = user
        entity.name = name
        entity.color = color
        entity.icon = icon
    }

    func apply(to entity: TagEntity) {
        entity.user = user
        entity.name = name
        entity.color = color
        entity.icon = icon
    }
}

struct BudgetRow: Codable, Equatable {
    var id: String
    var amount: Double
    var amountSource: Double
    var amountMinorUnits: Int64?
    var currencyCode: String
    var isConflicted: Bool
    var ownerID: String
    var mergedIntoID: String
    var resolutionToken: String
    var resolutionTimestamp: Double
    var resolvedTargetID: String
    var category: String
    var date: Int
    var summary: String

    init(_ entity: BudgetEntity) {
        id = entity.id
        amount = entity.amount
        amountSource = entity.amountSource
        amountMinorUnits = entity.amountMinorUnits
        currencyCode = entity.currencyCode
        isConflicted = entity.isConflicted
        ownerID = entity.ownerID
        mergedIntoID = entity.mergedIntoID
        resolutionToken = entity.resolutionToken
        resolutionTimestamp = entity.resolutionTimestamp
        resolvedTargetID = entity.resolvedTargetID
        category = entity.category
        date = entity.date
        summary = entity.summary
    }

    func apply(to entity: BudgetEntity) {
        entity.amount = amount
        entity.amountSource = amountSource
        entity.amountMinorUnits = amountMinorUnits
        entity.currencyCode = currencyCode
        entity.isConflicted = isConflicted
        entity.ownerID = ownerID
        entity.mergedIntoID = mergedIntoID
        entity.resolutionToken = resolutionToken
        entity.resolutionTimestamp = resolutionTimestamp
        entity.resolvedTargetID = resolvedTargetID
        entity.category = category
        entity.date = date
        entity.summary = summary
    }
}

struct ParticipantRow: Codable, Equatable {
    var id: String
    var user: String
    var name: String
    var photo: String
    var splitMode: Int
    var splitValue: Double
    var allocatedMinorUnits: Int64?
    var status: Int
    var transaction: String

    init(_ entity: ParticipantEntity) {
        id = entity.id
        user = entity.user
        name = entity.name
        photo = entity.photo
        splitMode = entity.splitMode
        splitValue = entity.splitValue
        allocatedMinorUnits = entity.allocatedMinorUnits
        status = entity.status
        transaction = entity.transaction
    }

    func apply(to entity: ParticipantEntity) {
        entity.user = user
        entity.name = name
        entity.photo = photo
        entity.splitMode = splitMode
        entity.splitValue = splitValue
        entity.allocatedMinorUnits = allocatedMinorUnits
        entity.status = status
        entity.transaction = transaction
    }
}
