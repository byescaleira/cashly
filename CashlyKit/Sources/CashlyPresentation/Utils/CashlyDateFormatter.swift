//
//  CashlyDateFormatter.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import RyzeFoundation

public enum CashlyDateFormatter: RyzeDateFormatter {
    case weekDay
    case sortPattern
    case defaultFormat
    case transactionSection
    case time
    case yearMonth
    case status
    case year
    case month
    case numberMonth
    
    public var rawValue: DateFormatter {
        switch self {
        case .weekDay: return getFormatter(from: "EEEE")
        case .defaultFormat: return getFormatter(from: "dd/MM/yyyy")
        case .sortPattern: return getFormatter(from: "yyyyMMdd")
        case .transactionSection: return getFormatter(from: "dd MMMM, yyyy")
        case .time: return getFormatter(from: "HH:mm")
        case .yearMonth: return getFormatter(from: "yyyyMM")
        case .status: return getFormatter(from: "MMMM, yyyy")
        case .year: return getFormatter(from: "yyyy")
        case .month: return getFormatter(from: "MMMM")
        case .numberMonth: return getFormatter(from: "MM")
        }
    }
}

public extension Date {
    func cashly(with formatter: CashlyDateFormatter) -> String {
        self.string(with: formatter) ?? ""
    }
}

public extension RyzeDateFormatter where Self == CashlyDateFormatter {
    static func cashly(_ formatter: CashlyDateFormatter) -> Self {
        formatter
    }
}
