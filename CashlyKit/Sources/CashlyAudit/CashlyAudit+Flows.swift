import CashlyData
import CashlyDomain
import CashlyPresentation
import Foundation
import SwiftData

extension CashlyAudit {
    /// Manual financial-flow diagnostic; operates on a fresh in-memory store.
    @MainActor static func inspectFlows() async throws {
        let factory = try CashlyDataFactory.make(inMemory: true)
        try await factory.makeUserUseCase().addUser(id: "flow-owner", name: "Perfil", photo: "1")
        try await factory.makeUserUseCase().addUser(id: "flow-other", name: "Outro", photo: "2")
        let scoped = factory.scoped(to: "flow-owner")
        try await scoped.makeCategoryUseCase().addCategory(
            id: "flow-category", user: "flow-owner", name: "Geral", color: "0099FF", icon: "cart")
        let transactions = scoped.makeTransactionUseCase()
        func record(
            _ id: String, kind: TransactionKind, cents: Int64, plan: Int? = nil,
            month: Int = 202601, status: TransactionStatus = .settled
        ) async throws {
            guard let date = Date.from(yearMonth: month) else {
                throw CashlyError.invalidInput("Competência inválida no diagnóstico financeiro.")
            }
            try await transactions.addTransaction(
                id: id, participants: [], categoryID: "flow-category", kind: kind,
                money: Money(minorUnits: cents),
                date: date.timeIntervalSince1970,
                summary: "Registro " + id, status: status, splitMode: nil, splitValue: nil,
                paymentsPlan: plan, tagIDs: [])
        }
        try await record("expense", kind: .expense, cents: 10001)
        try await record("installments", kind: .expense, cents: 10001, plan: 3)
        try await record("income", kind: .income, cents: 120005)
        let dashboard = scoped.makeDashboardUseCase()
        let initial = try await dashboard.overview(query: .init(month: 202601))
        guard initial.budgets.isEmpty, initial.expensesTotal.minorUnits == 13335,
            initial.incomeTotal.minorUnits == 120005, initial.netTotal.minorUnits == 106670
        else {
            throw CashlyError.persistence("Totais independentes do orçamento estão incorretos.")
        }
        guard let category = try await scoped.makeCategoryUseCase().getCategory(id: "flow-category")
        else { throw CashlyError.missingRecord }
        try await scoped.makeBudgetUseCase().addBudget(
            id: "flow-budget", amount: 200, category: category, date: 202601,
            summary: "Planejamento")
        let linked = try await dashboard.overview(query: .init(month: 202601))
        guard linked.budgetExpenses["flow-budget"]?.minorUnits == 13335 else {
            throw CashlyError.persistence("A associação por categoria e mês está incorreta.")
        }
        try await scoped.makeBudgetUseCase().addBudget(
            id: "flow-budget", amount: 200, category: category, date: 202602,
            summary: "Planejamento")
        let february = try await dashboard.overview(query: .init(month: 202602))
        let march = try await dashboard.overview(query: .init(month: 202603))
        guard february.budgetExpenses["flow-budget"]?.minorUnits == 3334,
            march.expensesTotal.minorUnits == 3333
        else {
            throw CashlyError.persistence("Competência e centavos das parcelas estão incorretos.")
        }
        try await scoped.makeBudgetUseCase().removeBudget(id: "flow-budget")
        let preserved = try await dashboard.page(query: .init(), after: nil, limit: 50)
        let incomePage = try await dashboard.page(
            query: .init(kinds: [.income]), after: nil, limit: 50)
        guard preserved.items.count == 3, incomePage.items.map(\.id) == ["income"] else {
            throw CashlyError.persistence(
                "Exclusão de orçamento ou filtro de entradas alterou registros.")
        }
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "cashly-flow-model-" + UUID().uuidString)
        let intelligence = LocalIntelligenceService(directory: directory)
        let dataset = try await dashboard.trainingData()
        let trained = try await intelligence.train(
            userID: "flow-owner", transactions: dataset.transactions, tags: dataset.tags,
            revision: dataset.revision)
        guard trained.allSatisfy({ $0.sampleCount == 2 }) else {
            throw CashlyError.persistence("Entradas contaminaram o treinamento de despesas.")
        }
        let foreign = try await factory.scoped(to: "flow-other").makeTransactionUseCase()
            .getTransaction(id: "income")
        guard foreign == nil else { throw CashlyError.persistence("Escopo financeiro violado.") }
        try await record("expense", kind: .expense, cents: 10001, month: 202602)
        let moved = try await dashboard.overview(query: .init(month: 202601))
        guard moved.expensesTotal.minorUnits == 3334 else {
            throw CashlyError.persistence("Editar a data não atualizou a competência.")
        }
        try await record("income", kind: .income, cents: 120005, status: .canceled)
        let canceled = try await dashboard.overview(query: .init(month: 202601))
        guard canceled.incomeTotal == .zero else {
            throw CashlyError.persistence("Entrada cancelada ainda participa dos totais.")
        }
        let form = TransactionViewModel(dataFactory: scoped)
        await form.load()
        form.draft.kind = .income
        guard let formDate = Date.from(yearMonth: 202602) else {
            throw CashlyError.invalidInput("Competência inválida no diagnóstico do formulário.")
        }
        form.draft.date = formDate
        form.draft.amount = 500.02
        form.draft.summary = "Entrada pelo formulário"
        await form.save()
        guard form.isSaved, let saved = try await transactions.getTransaction(id: form.draft.id),
            saved.kind == .income, saved.money.minorUnits == 50002
        else { throw CashlyError.persistence("Formulário de entrada não gravou sem orçamento.") }
        let edit = TransactionViewModel(draft: .edit(id: saved.id), dataFactory: scoped)
        await edit.load()
        guard edit.draft.kind == .income else {
            throw CashlyError.persistence("Edição perdeu o tipo entrada.")
        }
        edit.draft.amount = 500.03
        await edit.save()
        guard edit.isSaved else { throw CashlyError.persistence("Falha ao editar entrada.") }
        print("FLOWS noBudget=ok incomeMinor=120005 expenseMinor=13335 netMinor=106670")
        print("FLOWS dateAssociation=ok installments=3334/3334/3333 budgetRemoval=preserved")
        print("FLOWS incomeFilter=ok profileScope=ok dateEdit=ok canceledIncome=excluded")
        print("FLOWS expenseTraining=isolated incomeForm=created/edited withoutBudget=ok")
    }
}
