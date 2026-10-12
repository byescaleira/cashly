import Foundation

public struct StoreProduct: Hashable, Identifiable, Sendable {
    public let id: String
    public let displayPrice: String

    public init(id: String, displayPrice: String) {
        self.id = id
        self.displayPrice = displayPrice
    }
}

public struct StoreTransaction: Hashable, Identifiable, Sendable {
    public let id: UInt64
    public let productID: String
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let revocationDate: Date?
    public let isFreeTrial: Bool
    public let quantity: Int

    public init(
        id: UInt64, productID: String, purchaseDate: Date = .now, expirationDate: Date? = nil,
        revocationDate: Date? = nil, isFreeTrial: Bool = false, quantity: Int = 1
    ) {
        self.id = id
        self.productID = productID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.isFreeTrial = isFreeTrial
        self.quantity = quantity
    }

    var expiration: Date { expirationDate ?? .distantFuture }
}

public enum StorePurchase: Sendable {
    case success(StoreTransaction)
    case pending
    case cancelled
}

public protocol StoreClient: Sendable {
    var updates: AsyncStream<StoreTransaction> { get }
    func products(for ids: [String]) async throws -> [StoreProduct]
    func purchase(_ id: String) async throws -> StorePurchase
    func currentEntitlements() async -> [StoreTransaction]
    func latest(for id: String) async -> StoreTransaction?
    func unfinished() async -> [StoreTransaction]
    func finish(_ transaction: StoreTransaction) async
    func sync() async throws
}
