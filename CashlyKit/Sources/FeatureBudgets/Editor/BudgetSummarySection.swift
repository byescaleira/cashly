import CashlyDesignSystem
import SwiftUI

struct BudgetSummarySection: View {
    @Environment(BudgetEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Describe this budget", text: $model.draft.summary, axis: .vertical)
        } header: {
            Text("Description").sectionTitle()
        }
    }
}
