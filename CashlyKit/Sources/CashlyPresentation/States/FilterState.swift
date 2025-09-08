//
//  FilterState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain

public struct FilterState: CashlyState, Equatable, Hashable {
    public var startDate: Date
    public var endDate: Date?
    public var transactionStatuses: Set<TransactionStatus>
    public var categories: Set<CashlyDomain.Category>
    public var tags: Set<Tag>
    public var user: User?
    public var isFilteringByDate: Bool
    
    public init(
        startDate: Date = .now,
        endDate: Date? = nil,
        transactionStatuses: Set<TransactionStatus> = [],
        categories: Set<CashlyDomain.Category> = [],
        tags: Set<Tag> = [],
        user: User? = nil,
        isFilteringByDate: Bool = true
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.transactionStatuses = transactionStatuses
        self.categories = categories
        self.tags = tags
        self.user = user
        self.isFilteringByDate = isFilteringByDate
    }
}
