//
//  MockTag.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import CashlyResource
import RyzeFoundation

extension Tag: RyzeMock {
    public static var mock: Tag {
        mocks.randomElement()!
    }
    
    public static var mocks: [Tag] {
        let tags: [Tag] = CashlyResourceFile.tags.decoded()
        return tags.sorted(by: \.name)
    }
}
