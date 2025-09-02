//
//  CashlyKey.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import Foundation
import RyzeFoundation

public enum CashlyKey: CashlyEntity {
    case budget(category: UUID, date: TimeInterval)
    case category(id: UUID)
    
    public var id: String {
        rawValue
    }
    
    public var rawValue: String {
        switch self {
        case let .budget(category, date):
            guard let month = Calendar.current.dateComponents([.month], from: date.date).month else {
                fatalError("🗓️ Failed to extract month from date.")
            }
            return "\(category.uuidString).\(month)"
        case let .category(id):
            return id.uuidString
        }
    }
}
