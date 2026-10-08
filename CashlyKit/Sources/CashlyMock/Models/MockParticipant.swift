import CashlyDomain
import CashlyResource
import Foundation

extension Participant {
    public static var mock: Participant {
        mocks.first
            ?? Participant(
                id: "preview-participant", user: .mock, splitMode: .equal, splitValue: 2,
                status: .settled,
                transaction: "preview-transaction")
    }

    public static var mocks: [Participant] {
        let participants: [Participant] = (try? CashlyResourceFile.participants.decoded()) ?? []
        return participants.sorted(by: \.user.name)
    }
}
