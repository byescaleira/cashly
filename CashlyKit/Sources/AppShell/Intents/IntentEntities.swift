import AppIntents
import CashlyDomain
import FeatureCore
import Foundation

enum IntentWorkspace {
    @MainActor static func actions(writing: Bool = false, profileID: String? = nil) async throws
        -> IntentActions
    {
        if writing, await !CashlyServices.shared.canWrite() {
            throw CashlyError.invalidInput(
                String(appLocalized: "Recording needs Cashly Pro. Open Cashly to subscribe."))
        }
        let (repositories, user) = try await CashlyServices.shared.workspace(userID: profileID)
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
    @IntentParameterDependency<AddExpenseIntent>(\.$profile) var expense
    @IntentParameterDependency<AddIncomeIntent>(\.$profile) var income

    public init() {}

    public func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        try await categories().filter { identifiers.contains($0.id) }
    }

    public func entities(matching string: String) async throws -> [CategoryEntity] {
        try await categories().filter { $0.name.localizedStandardContains(string) }
    }

    public func suggestedEntities() async throws -> [CategoryEntity] {
        try await categories()
    }

    private func categories() async throws -> [CategoryEntity] {
        let profileID = expense?.profile.id ?? income?.profile.id
        return try await IntentWorkspace.actions(profileID: profileID).categories()
            .map(CategoryEntity.init)
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
    @IntentParameterDependency<AddExpenseIntent>(\.$profile) var expense
    @IntentParameterDependency<AddIncomeIntent>(\.$profile) var income

    public init() {}

    public func entities(for identifiers: [String]) async throws -> [TagEntity] {
        try await tags().filter { identifiers.contains($0.id) }
    }

    public func entities(matching string: String) async throws -> [TagEntity] {
        try await tags().filter { $0.name.localizedStandardContains(string) }
    }

    public func suggestedEntities() async throws -> [TagEntity] {
        try await tags()
    }

    private func tags() async throws -> [TagEntity] {
        let profileID = expense?.profile.id ?? income?.profile.id
        return try await IntentWorkspace.actions(profileID: profileID).tags().map(TagEntity.init)
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

public struct ParticipantOptions: DynamicOptionsProvider {
    @IntentParameterDependency<AddExpenseIntent>(\.$profile) var expense

    public init() {}

    public func results() async throws -> [ProfileEntity] {
        try await IntentWorkspace.actions(profileID: expense?.profile.id).participants()
            .map(ProfileEntity.init)
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
