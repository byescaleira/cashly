import Foundation

public enum CashlyError: Error, LocalizedError, Equatable, Sendable {
    case onFetch, onSave, onRemove
    case invalidInput(String)
    case missingRecord
    case persistence(String)
    case intelligence(String)

    public var errorDescription: String? {
        switch self {
        case .onFetch: "Não foi possível carregar os dados. Tente novamente."
        case .onSave: "Não foi possível salvar. Confira os campos e tente novamente."
        case .onRemove: "Não foi possível excluir. Verifique os registros vinculados."
        case .invalidInput(let message), .persistence(let message), .intelligence(let message):
            message
        case .missingRecord: "O registro não existe mais. Atualize a lista."
        }
    }
}
