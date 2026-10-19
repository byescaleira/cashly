import CashlyDomain
import Foundation

public struct StoreProduct: Hashable, Identifiable, Sendable {
    public enum Period: Sendable {
        case month, year

        public var months: Int {
            switch self {
            case .month: 1
            case .year: 12
            }
        }
    }

    public let id: String
    public let displayPrice: String
    public let price: Decimal
    public let priceStyle: Decimal.FormatStyle.Currency?
    public let period: Period?
    public let trialDays: Int?

    public init(
        id: String, displayPrice: String, price: Decimal = 0,
        priceStyle: Decimal.FormatStyle.Currency? = nil, period: Period? = nil,
        trialDays: Int? = nil
    ) {
        self.id = id
        self.displayPrice = displayPrice
        self.price = price
        self.priceStyle = priceStyle
        self.period = period
        self.trialDays = trialDays
    }

    public func formatted(_ amount: Decimal) -> String {
        priceStyle?.format(amount) ?? displayPrice
    }
}

public struct StoreTransaction: Hashable, Identifiable, Sendable {
    public let id: UInt64
    public let productID: String
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let revocationDate: Date?
    public let isFreeTrial: Bool
    public let isUpgraded: Bool
    public let quantity: Int

    public init(
        id: UInt64, productID: String, purchaseDate: Date = .now, expirationDate: Date? = nil,
        revocationDate: Date? = nil, isFreeTrial: Bool = false, isUpgraded: Bool = false,
        quantity: Int = 1
    ) {
        self.id = id
        self.productID = productID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.isFreeTrial = isFreeTrial
        self.isUpgraded = isUpgraded
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
    var statusUpdates: AsyncStream<Void> { get }
    func products(for ids: [String]) async throws -> [StoreProduct]
    func isEligibleForIntroOffer(_ id: String) async -> Bool
    func purchase(_ id: String) async throws -> StorePurchase
    func currentEntitlements() async -> [StoreTransaction]
    func history() async -> [StoreTransaction]
    func latest(for id: String) async -> StoreTransaction?
    func subscriptionStatuses() async -> [ProSubscription]
    func unfinished() async -> [StoreTransaction]
    func finish(_ transaction: StoreTransaction) async
    func sync() async throws
}
