import CashlyDomain
import FeatureCore
import SwiftUI

public struct BudgetConflictScreen: View {
    @Environment(BudgetConflictModel.self) private var model
    @Environment(FinanceModel.self) private var finance
    @Environment(\.close) private var close

    public init() {}

    public var body: some View {
        @Bindable var model = model
        List {
            Section {
                Text(
                    "Escolha o valor planejado que deve prevalecer. As transações serão reunidas nesse orçamento; os outros registros serão preservados como histórico do conflito."
                )
            }
            if let conflict = model.conflict {
                ForEach(conflict.budgets) { budget in
                    Section {
                        LabeledContent("Valor", value: budget.money.formatted)
                        Text(budget.summary)
                        Button("Manter este orçamento") {
                            Task { if await model.keep(budget) { close() } }
                        }
                    }
                }
            } else if model.isLoading {
                ProgressView()
            } else {
                Text("Este conflito já foi resolvido. Atualize os dados para continuar.")
            }
        }
        .navigationTitle("Resolver orçamento")
        .task(id: finance.contentGeneration) { await model.load() }
        .disabled(model.isLocked)
        .interactiveDismissDisabled(model.isSaving)
        .errorAlert($model.error)
    }
}
