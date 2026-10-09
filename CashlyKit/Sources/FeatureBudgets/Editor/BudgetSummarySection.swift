import CashlyDesignSystem
import SwiftUI

struct BudgetSummarySection: View {
    @Environment(BudgetEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Descreva este orçamento", text: $model.draft.summary, axis: .vertical)
        } header: {
            Text("Descrição").sectionTitle()
        }
    }
}
