//
//  CashlyError.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import RyzeFoundation

public enum CashlyError: RyzeError {
    case onFetch
    case onSave
    case onRemove
    
    public var description: String {
        ""
    }
}
