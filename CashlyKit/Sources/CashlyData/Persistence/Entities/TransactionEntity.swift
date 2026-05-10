//
//  TransactionEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import SwiftData
import Foundation
import RyzeFoundation

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
    
    public var yearMonth: Int {
        date.yearMonth
    }
    
    public var endDate: Set<Int>? {
        guard let paymentsPlan else { return nil }
        var range: Set<Int> = []
        let yearMonth = self.yearMonth
        
        for payment in 1 ... paymentsPlan {
            let additionalMonths = payment - 1
            let year = yearMonth / 100
            let month = yearMonth % 100
            let newYear = month + additionalMonths > 12 ? year + 1 : year
            let newMonth = month + additionalMonths > 12 ? month + additionalMonths - 12 : month + additionalMonths
            let newYearMonth = newYear * 100 + newMonth
            range.insert(newYearMonth)
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
        paymentsPlan: Int? = nil
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
    }
}

enum TransactionDateFormatter: RyzeDateFormatter {
    case yearMonth
    case shareMessage
    
    var rawValue: DateFormatter {
        switch self {
        case .yearMonth: getFormatter(from: "yyyyMM")
        case .shareMessage: getFormatter(from: "dd MMMM, yyyy | HH:mm")
        }
    }
}

extension RyzeDateFormatter where Self == TransactionDateFormatter {
    static func transaction(_ formatter: TransactionDateFormatter) -> Self {
        formatter
    }
}
