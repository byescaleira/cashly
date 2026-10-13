import Foundation
import StoreKit

public actor StoreKitClient: StoreClient {
    private var products: [String: Product] = [:]
    private var open: [UInt64: StoreKit.Transaction] = [:]

    public init() {}

    public nonisolated var updates: AsyncStream<StoreTransaction> {
        AsyncStream { continuation in
            let task = Task {
                for await result in StoreKit.Transaction.updates {
                    if let transaction = await keep(result) { continuation.yield(transaction) }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func products(for ids: [String]) async throws -> [StoreProduct] {
        let loaded = try await Product.products(for: ids)
        for product in loaded { products[product.id] = product }
        return loaded.map(StoreProduct.init)
    }

    public func isEligibleForIntroOffer(_ id: String) async -> Bool {
        if products[id] == nil { _ = try? await products(for: [id]) }
        guard let subscription = products[id]?.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    public func purchase(_ id: String) async throws -> StorePurchase {
        if products[id] == nil { _ = try await products(for: [id]) }
        guard let product = products[id] else { throw StoreKitError.unknown }
        switch try await confirm(product) {
        case .success(let result):
            guard let transaction = keep(result) else { throw StoreKitError.unknown }
            return .success(transaction)
        case .pending: return .pending
        case .userCancelled: return .cancelled
        @unknown default: return .cancelled
        }
    }

    public func currentEntitlements() async -> [StoreTransaction] {
        var values: [StoreTransaction] = []
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = keep(result) { values.append(transaction) }
        }
        return values
    }

    public func latest(for id: String) async -> StoreTransaction? {
        guard let result = await StoreKit.Transaction.latest(for: id) else { return nil }
        return keep(result)
    }

    public func unfinished() async -> [StoreTransaction] {
        var values: [StoreTransaction] = []
        for await result in StoreKit.Transaction.unfinished {
            if let transaction = keep(result) { values.append(transaction) }
        }
        return values
    }

    public func finish(_ transaction: StoreTransaction) async {
        await open.removeValue(forKey: transaction.id)?.finish()
    }

    public func sync() async throws {
        try await AppStore.sync()
    }

    private func keep(_ result: VerificationResult<StoreKit.Transaction>) -> StoreTransaction? {
        guard case .verified(let transaction) = result else { return nil }
        open[transaction.id] = transaction
        return StoreTransaction(transaction)
    }

    private func confirm(_ product: Product) async throws -> Product.PurchaseResult {
        #if os(visionOS)
            guard
                let scene = await MainActor.run(body: { UIApplication.shared.connectedScenes.first }
                )
            else { throw StoreKitError.unknown }
            return try await product.purchase(confirmIn: scene)
        #else
            return try await product.purchase()
        #endif
    }
}

extension StoreProduct {
    fileprivate init(_ product: Product) {
        let offer = product.subscription?.introductoryOffer
        self.init(
            id: product.id, displayPrice: product.displayPrice, price: product.price,
            priceStyle: product.priceFormatStyle,
            period: product.subscription.flatMap { Period($0.subscriptionPeriod) },
            trialDays: offer?.paymentMode == .freeTrial ? offer.map { $0.period.days } : nil)
    }
}

extension StoreProduct.Period {
    fileprivate init?(_ period: Product.SubscriptionPeriod) {
        switch (period.unit, period.value) {
        case (.month, 1): self = .month
        case (.year, 1): self = .year
        default: return nil
        }
    }
}

extension Product.SubscriptionPeriod {
    fileprivate var days: Int {
        switch unit {
        case .day: value
        case .week: value * 7
        case .month: value * 30
        case .year: value * 365
        @unknown default: value
        }
    }
}

extension StoreTransaction {
    fileprivate init(_ transaction: StoreKit.Transaction) {
        self.init(
            id: transaction.id, productID: transaction.productID,
            purchaseDate: transaction.purchaseDate, expirationDate: transaction.expirationDate,
            revocationDate: transaction.revocationDate,
            isFreeTrial: transaction.offer?.paymentMode == .freeTrial,
            quantity: transaction.purchasedQuantity)
    }
}
