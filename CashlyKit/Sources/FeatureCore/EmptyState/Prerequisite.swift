import SwiftUI

public enum Prerequisite: CaseIterable, Sendable {
    case category, transaction, tag, budget

    var title: LocalizedStringKey {
        switch self {
        case .category: "Nenhuma categoria ainda"
        case .transaction: "Nenhuma transação neste período"
        case .tag: "Nenhuma tag ainda"
        case .budget: "Nenhum orçamento neste mês"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .category: "Categorias mostram para onde vai o seu dinheiro."
        case .transaction: "Registre entradas e saídas para acompanhar o mês."
        case .tag: "Tags agrupam os gastos de uma viagem, evento ou projeto."
        case .budget: "Diga quanto quer gastar em cada categoria e acompanhe o ritmo do mês."
        }
    }

    var actionTitle: LocalizedStringKey {
        switch self {
        case .category: "Adicionar categoria"
        case .transaction: "Adicionar transação"
        case .tag: "Adicionar tag"
        case .budget: "Criar orçamento"
        }
    }

    var route: Route {
        switch self {
        case .category: .addCategory(id: nil)
        case .transaction: .addTransaction(id: nil)
        case .tag: .addTag(id: nil)
        case .budget: .addBudget(id: nil, categoryID: nil, date: nil)
        }
    }
}
