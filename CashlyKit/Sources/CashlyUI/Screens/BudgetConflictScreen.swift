import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI

public struct BudgetConflictScreen: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(\.close) private var close
    let categoryID: String
    let month: YearMonth
    @State private var conflict: BudgetConflict?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var error: CashlyError?

    public init(categoryID: String, month: YearMonth) {
        self.categoryID = categoryID
        self.month = month
    }

    public var body: some View {
        List {
            Section {
                Text(
                    "Escolha o valor planejado que deve prevalecer. As transações serão reunidas nesse orçamento; os outros registros serão preservados como histórico do conflito."
                )
            }
            if let conflict {
                ForEach(conflict.budgets) { budget in
                    Section {
                        LabeledContent("Valor", value: budget.money.formatted)
                        Text(budget.summary)
                        Button("Manter este orçamento") {
                            isSaving = true
                            Task {
                                defer { isSaving = false }
                                do {
                                    try await finance.resolveBudgetConflict(keeping: budget.id)
                                    close()
                                } catch { self.error = error as? CashlyError ?? .onSave }
                            }
                        }
                    }
                }
            } else if isLoading {
                ProgressView()
            } else {
                Text("Este conflito já foi resolvido. Atualize os dados para continuar.")
            }
        }
        .navigationTitle("Resolver orçamento")
        .task(id: finance.contentGeneration) {
            isLoading = true
            defer { isLoading = false }
            do {
                conflict = try await finance.budgetConflict(categoryID: categoryID, month: month)
            } catch {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
        .disabled(isSaving || isLoading)
        .interactiveDismissDisabled(isSaving)
        .cashlyErrorAlert(error: $error)
    }
}
