import CashlyResource
import SwiftUI

public enum Prerequisite: CaseIterable, Sendable {
    case user, category, budget, tag

    var image: CashlyResourceImage {
        switch self {
        case .user: .illustrationPeople
        case .category: .illustrationEmpty
        case .budget: .illustrationNoData
        case .tag: .illustrationTag
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .user: "Nenhum usuário ainda"
        case .category: "Nenhuma categoria ainda"
        case .budget: "Nenhum orçamento neste período"
        case .tag: "Nenhuma tag ainda"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .user: "Adicione um usuário para começar a organizar as finanças."
        case .category: "Categorias mostram para onde vai o seu dinheiro."
        case .budget: "Defina quanto quer gastar em cada categoria para acompanhar o mês."
        case .tag: "Tags agrupam os gastos de uma viagem, evento ou projeto."
        }
    }

    var actionTitle: LocalizedStringKey {
        switch self {
        case .user: "Adicionar usuário"
        case .category: "Adicionar categoria"
        case .budget: "Adicionar orçamento"
        case .tag: "Adicionar tag"
        }
    }

    var route: Route {
        switch self {
        case .user: .addUser(id: nil)
        case .category: .addCategory(id: nil)
        case .budget: .addBudget(id: nil, categoryID: nil, date: nil)
        case .tag: .addTag(id: nil)
        }
    }

    @MainActor func isMissing(session: SessionModel, finance: FinanceModel) -> Bool {
        switch self {
        case .user: session.users.isEmpty
        case .category: finance.categories.isEmpty
        case .budget: finance.budgets.isEmpty
        case .tag: finance.tags.isEmpty
        }
    }
}
