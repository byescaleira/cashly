//
//  MockTransaction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import CashlyResource
import RyzeFoundation

extension CashlyDomain.Transaction: RyzeMock {
    public static var mock: CashlyDomain.Transaction {
        mocks.randomElement()!
    }
    
    public static var mocks: [CashlyDomain.Transaction] {
        let transactions: [CashlyDomain.Transaction] = CashlyResourceFile.transactions.decoded()
        return transactions.sorted(by: \.date, using: >)
    }
}
