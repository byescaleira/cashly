//
//  MockUser.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import CashlyResource
import RyzeFoundation

extension User: RyzeMock {
    public static var mock: User {
        mocks.randomElement()!
    }
    
    public static var mocks: [User] {
        let users: [User] = (try? CashlyResourceFile.users.decoded()) ?? []
        return users.sorted { $0.name < $1.name }
    }
}
