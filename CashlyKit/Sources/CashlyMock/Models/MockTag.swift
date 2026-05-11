//
//  MockTag.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import CashlyResource
import PrismFoundation

extension Tag: PrismMock {
    public static var mock: Tag {
        mocks.randomElement()!
    }

    public static var mocks: [Tag] {
        let tags: [Tag] = (try? CashlyResourceFile.tags.decoded()) ?? []
        return tags.sorted { $0.name < $1.name }
    }
}
