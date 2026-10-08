public struct CashlySnapshot: Sendable {
    public let users: [User]
    public let currentUser: User?
    public let categories: [Category]
    public let budgets: [Budget]
    public let tags: [Tag]
    public var pendingReferences = 0

    public init(
        users: [User], currentUser: User?, categories: [Category], budgets: [Budget], tags: [Tag]
    ) {
        self.users = users
        self.currentUser = currentUser
        self.categories = categories
        self.budgets = budgets
        self.tags = tags
    }
}
