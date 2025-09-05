//
//  MockCategory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import CashlyDomain
import CashlyResource
import RyzeFoundation

extension CashlyDomain.Category: RyzeMock {
    public static var mock: CashlyDomain.Category {
        mocks.randomElement()!
    }
    
    public static var mocks: [CashlyDomain.Category] {
        let categories: [CashlyDomain.Category] = CashlyResourceFile.categories.decoded()
        return categories.sorted(by: \.name)
    }
}
