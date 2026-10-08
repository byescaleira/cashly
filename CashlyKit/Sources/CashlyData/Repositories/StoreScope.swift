import CashlyDomain

struct StoreScope: Sendable {
    let store: CashlyStore
    let userID: String?

    func requireUserID() throws -> String {
        guard let userID else {
            throw CashlyError.invalidInput("Selecione um usuário antes de continuar.")
        }
        return userID
    }

    func requireOwner(_ ownerID: String) throws -> String {
        let userID = try requireUserID()
        guard ownerID == userID else { throw CashlyError.onSave }
        return userID
    }
}
