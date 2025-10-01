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
    public var allCategories: [CashlyDomain.Category] = []
    public var allTags: [Tag] = []
    public var allStatuses: [TransactionStatus] = []
    public var allTransactions: [CashlyDomain.Transaction] = []
    public var transactionStatuses: Set<TransactionStatus>
    public var categories: Set<CashlyDomain.Category>
    public var tags: Set<Tag>
    public var participants: Set<User>
    public var isFilteringByDate: Bool
    
    public init(
        startDate: Date = .now,
        endDate: Date? = nil,
        transactionStatuses: Set<TransactionStatus> = [],
        categories: Set<CashlyDomain.Category> = [],
        tags: Set<Tag> = [],
        participants: Set<User> = [],
        isFilteringByDate: Bool = true
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.transactionStatuses = transactionStatuses
        self.categories = categories
        self.tags = tags
        self.participants = participants
        self.isFilteringByDate = isFilteringByDate
    }
}
