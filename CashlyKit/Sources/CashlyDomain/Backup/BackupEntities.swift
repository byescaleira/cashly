public struct BackupEntities: Sendable {
    public let users: [User]
    public let categories: [Category]
    public let tags: [Tag]
    public let budgets: [Budget]
    public let transactions: [Transaction]
}
