//
//  MockParticipant.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import CashlyDomain
import CashlyResource
import RyzeFoundation

extension Participant: RyzeMock {
    public static var mock: Participant {
        mocks.randomElement()!
    }
    
    public static var mocks: [Participant] {
        let participants: [Participant] = (try? CashlyResourceFile.participants.decoded()) ?? []
        return participants.sorted { $0.user.name < $1.user.name }
    }
}
