import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI

struct BudgetConflictScreen: View {
    @Environment(MainViewModel.self) private var main
    @Environment(\.dismiss) private var dismiss
    let categoryID: String
    let month: YearMonth
    @State private var conflict: BudgetConflict?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var error: CashlyError?
    var body: some View {
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
                                    try await main.resolveBudgetConflict(keeping: budget.id)
                                    dismiss()
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
        .task(id: main.contentGeneration) {
            isLoading = true
            defer { isLoading = false }
            do {
                conflict = try await main.budgetConflict(categoryID: categoryID, month: month)
            } catch {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
        .disabled(isSaving || isLoading)
        .interactiveDismissDisabled(isSaving)
        .cashlyErrorAlert(error: $error)
    }
}
