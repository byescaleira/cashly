import CashlyDomain
import CashlyResource
import Foundation

extension User {
    public static var mock: User {
        mocks.first ?? User(id: "preview-user", name: "Rafael", photo: "1")
    }

    public static var mocks: [User] {
        let users: [User] = (try? CashlyResourceFile.users.decoded()) ?? []
        return users.sorted(by: \.name)
    }
}
