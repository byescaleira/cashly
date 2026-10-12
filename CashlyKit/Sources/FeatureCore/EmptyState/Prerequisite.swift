import SwiftUI

public enum Prerequisite: CaseIterable, Sendable {
    case category, transaction, tag

    var title: LocalizedStringKey {
        switch self {
        case .category: "Nenhuma categoria ainda"
        case .transaction: "Nenhuma transação neste período"
        case .tag: "Nenhuma tag ainda"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .category: "Categorias mostram para onde vai o seu dinheiro."
        case .transaction: "Registre entradas e saídas para acompanhar o mês."
        case .tag: "Tags agrupam os gastos de uma viagem, evento ou projeto."
        }
    }

    var actionTitle: LocalizedStringKey {
        switch self {
        case .category: "Adicionar categoria"
        case .transaction: "Adicionar transação"
        case .tag: "Adicionar tag"
        }
    }

    var route: Route {
        switch self {
        case .category: .addCategory(id: nil)
        case .transaction: .addTransaction(id: nil)
        case .tag: .addTag(id: nil)
        }
    }
}
