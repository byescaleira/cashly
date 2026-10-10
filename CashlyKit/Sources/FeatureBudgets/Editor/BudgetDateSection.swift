import CashlyDesignSystem
import SwiftUI

struct BudgetDateSection: View {
    @Environment(BudgetEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            DatePicker("Mês", selection: $model.draft.date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.vertical, -16)
        } header: {
            Text("Data").sectionTitle()
        }
    }
}
