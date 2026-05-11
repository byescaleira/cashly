//
//  CashlyKey.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import Foundation
import PrismFoundation

public enum CashlyKey: CashlyEntity {
    case budget(category: String, date: TimeInterval)
    case category(id: String)
    
    public var id: String {
        rawValue
    }
    
    public var rawValue: String {
        switch self {
        case let .budget(category, date):
            let month = Calendar.current.component(.month, from: date.date)
            return "\(category).\(month)"
        case let .category(id):
            return id
        }
    }
}
