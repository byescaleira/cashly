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
    
    public var rawValue: DateFormatter {
        switch self {
        case .weekDay: return getFormatter(from: "EEEE")
        case .defaultFormat: return getFormatter(from: "dd/MM/yyyy")
        case .sortPattern: return getFormatter(from: "yyyyMMdd")
        case .transactionSection: return getFormatter(from: "dd MMMM, yyyy")
        case .time: return getFormatter(from: "HH:mm")
        }
    }
}

public extension Date {
    func cashly(with formatter: CashlyDateFormatter) -> String {
        self.string(with: formatter) ?? ""
    }
}
