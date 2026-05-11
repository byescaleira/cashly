//
//  MockTransaction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import CashlyResource
import PrismFoundation

extension CashlyDomain.Transaction: PrismMock {
    public static var mock: CashlyDomain.Transaction {
        mocks.randomElement()!
    }

    public static var mocks: [CashlyDomain.Transaction] {
        let transactions: [CashlyDomain.Transaction] = (try? CashlyResourceFile.transactions.decoded()) ?? []
        return transactions.sorted { $0.date > $1.date }
    }
}
