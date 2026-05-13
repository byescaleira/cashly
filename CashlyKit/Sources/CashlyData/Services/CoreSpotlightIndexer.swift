//
//  CoreSpotlightIndexer.swift
//  CashlyKit
//
//  CoreSpotlight-backed `SpotlightIndexerUseCase`. Builds one
//  `CSSearchableItem` per transaction with the budget category as
//  domain identifier — easy bulk deletion when a category is wiped.
//

#if canImport(CoreSpotlight)
import Foundation
import CoreSpotlight
import UniformTypeIdentifiers
import CashlyDomain

public actor CoreSpotlightIndexer: SpotlightIndexerUseCase {
    private let domainIdentifier = "com.cashly.app.transactions"

    public init() {}

    public func index(transactions: [Transaction]) async {
        let items = transactions.map { Self.makeItem(from: $0, domain: domainIdentifier) }
        do {
            try await CSSearchableIndex.default()
                .deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
            try await CSSearchableIndex.default().indexSearchableItems(items)
        } catch {
            // Best-effort — silently swallow. Spotlight failures
            // never block the app.
        }
    }

    public func clear() async {
        try? await CSSearchableIndex.default()
            .deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
    }

    private static func makeItem(
        from transaction: Transaction,
        domain: String
    ) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .item)
        attributes.title = transaction.summary
        attributes.contentDescription = "\(transaction.effectiveCategory.name) — \(transaction.amount)"
        attributes.keywords = [
            transaction.effectiveCategory.name,
            transaction.budget?.summary ?? ""
        ]
        return CSSearchableItem(
            uniqueIdentifier: transaction.id,
            domainIdentifier: domain,
            attributeSet: attributes
        )
    }
}
#endif
