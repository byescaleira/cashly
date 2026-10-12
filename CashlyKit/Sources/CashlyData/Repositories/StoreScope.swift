import CashlyDomain

struct StoreScope: Sendable {
    let store: CashlyStore
    let userID: String?

    func requireUserID() throws -> String {
        guard let userID else {
            throw CashlyError.invalidInput(String(appLocalized: "Select a user before continuing."))
        }
        return userID
    }

    func requireOwner(_ ownerID: String) throws -> String {
        let userID = try requireUserID()
        guard ownerID == userID else { throw CashlyError.onSave }
        return userID
    }
}
