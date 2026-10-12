import AppIntents
import CashlyDomain
import FeatureCore
import Foundation

enum IntentWorkspace {
    @MainActor static func actions(writing: Bool = false) async throws -> IntentActions {
        if writing, await !CashlyServices.shared.canWrite() {
            throw CashlyError.invalidInput(
                String(appLocalized: "Recording needs Cashly Pro. Open Cashly to subscribe."))
        }
        let (repositories, user) = try await CashlyServices.shared.workspace()
        return IntentActions(repositories: repositories, user: user)
    }
}

public struct CategoryEntity: AppEntity, IndexedEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
    public static let defaultQuery = CategoryQuery()

    public let id: String
    public let name: String
    public let icon: String

    public init(_ category: CashlyDomain.Category) {
        id = category.id
        name = category.name
        icon = category.icon
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: icon))
    }
}

public struct CategoryQuery: EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        try await IntentWorkspace.actions().categories()
            .filter { identifiers.contains($0.id) }.map(CategoryEntity.init)
    }

    public func entities(matching string: String) async throws -> [CategoryEntity] {
        try await IntentWorkspace.actions().categories()
            .filter { $0.name.localizedStandardContains(string) }.map(CategoryEntity.init)
    }

    public func suggestedEntities() async throws -> [CategoryEntity] {
        try await IntentWorkspace.actions().categories().map(CategoryEntity.init)
    }
}

public struct TagEntity: AppEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tag")
    public static let defaultQuery = TagQuery()

    public let id: String
    public let name: String

    public init(_ tag: Tag) {
        id = tag.id
        name = tag.name
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

public struct TagQuery: EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [TagEntity] {
        try await IntentWorkspace.actions().tags().filter { identifiers.contains($0.id) }
            .map(TagEntity.init)
    }

    public func entities(matching string: String) async throws -> [TagEntity] {
        try await IntentWorkspace.actions().tags()
            .filter { $0.name.localizedStandardContains(string) }.map(TagEntity.init)
    }

    public func suggestedEntities() async throws -> [TagEntity] {
        try await IntentWorkspace.actions().tags().map(TagEntity.init)
    }
}

public struct ProfileEntity: AppEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Profile")
    public static let defaultQuery = ProfileQuery()

    public let id: String
    public let name: String

    public init(_ user: User) {
        id = user.id
        name = user.name
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

public struct ProfileQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [ProfileEntity] {
        try await users().filter { identifiers.contains($0.id) }.map(ProfileEntity.init)
    }

    public func suggestedEntities() async throws -> [ProfileEntity] {
        try await users().map(ProfileEntity.init)
    }

    @MainActor private func users() async throws -> [User] {
        try await CashlyServices.shared.workspace().0.users.users()
    }
}

public struct PendingBillEntity: AppEntity {
    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Pending Bill")
    public static let defaultQuery = PendingBillQuery()

    public let id: String
    public let summary: String
    public let amount: String
    public let date: Date

    public init(_ transaction: Transaction) {
        id = transaction.id
        summary = transaction.summary.isEmpty ? transaction.category.name : transaction.summary
        amount = transaction.money.formatted
        date = transaction.date
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(summary)",
            subtitle: "\(amount) · \(date.formatted(Date.FormatStyle(locale: .app).day().month()))")
    }
}

public struct PendingBillQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [PendingBillEntity] {
        try await IntentWorkspace.actions().pendingBills()
            .filter { identifiers.contains($0.id) }.map(PendingBillEntity.init)
    }

    public func suggestedEntities() async throws -> [PendingBillEntity] {
        try await IntentWorkspace.actions().pendingBills().map(PendingBillEntity.init)
    }
}
