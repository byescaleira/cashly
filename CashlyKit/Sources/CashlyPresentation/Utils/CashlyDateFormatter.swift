//
//  CashlyDateFormatter.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import RyzeFoundation

public enum CashlyDateFormatter: RyzeDateFormatter {
    case weekDay
    
    public var rawValue: DateFormatter {
        switch self {
        case .weekDay: return getFormatter(from: "EEEE")
        }
    }
}
