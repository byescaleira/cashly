//
//  TransactionEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import SwiftData
import Foundation
import PrismFoundation

@Model
public class TransactionEntity {
    public var id: String = ""
    public var participants: [String] = []
    public var budget: String = ""
    public var amount: Double = 0
    public var date: TimeInterval = 0
    public var summary: String = ""
    public var status: Int = 0
    public var splitMode: Int?
    public var splitValue: Double?
    public var paymentsPlan: Int?
    /// TransactionKind raw value. Defaults to `0` (.expense) so
    /// pre-J2 rows materialize as expenses on first read.
    public var kind: Int = 0
    /// `true` when the transaction was captured from dictation (J8+)
    /// and one or more fields could not be inferred.
    public var needsReview: Bool = false

    public var yearMonth: Int {
        date.yearMonth
    }

    public var endDate: Set<Int>? {
        guard let paymentsPlan else { return nil }
        var range: Set<Int> = []
        let yearMonth = self.yearMonth
        let baseYear = yearMonth / 100
        let baseMonth = yearMonth % 100

        // Modular roll-over: the previous form only added a single
        // year, so plans crossing two+ years produced an out-of-range
        // month (e.g. month=18) and a wrong year. Convert the base
        // month + payment offset into total months from year zero,
        // then split back into (year, month).
        for payment in 1 ... paymentsPlan {
            let additionalMonths = payment - 1
            let totalMonths = (baseMonth - 1) + additionalMonths
            let newYear = baseYear + totalMonths / 12
            let newMonth = (totalMonths % 12) + 1
            range.insert(newYear * 100 + newMonth)
        }

        return range
    }

    public init(
        id: String,
        participants: [String],
        budget: String,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int,
        splitMode: Int? = nil,
        splitValue: Double? = nil,
        paymentsPlan: Int? = nil,
        kind: Int = 0,
        needsReview: Bool = false
    ) {
        self.id = id
        self.participants = participants
        self.budget = budget
        self.amount = amount
        self.date = date
        self.summary = summary
        self.status = status
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.paymentsPlan = paymentsPlan
        self.kind = kind
        self.needsReview = needsReview
    }
}

enum TransactionDateFormatter: PrismDateFormatter {
    case yearMonth
    case shareMessage

    var rawValue: DateFormatter {
        switch self {
        case .yearMonth: getFormatter(from: "yyyyMM")
        case .shareMessage: getFormatter(from: "dd MMMM, yyyy | HH:mm")
        }
    }
}

extension PrismDateFormatter where Self == TransactionDateFormatter {
    static func transaction(_ formatter: TransactionDateFormatter) -> Self {
        formatter
    }
}
