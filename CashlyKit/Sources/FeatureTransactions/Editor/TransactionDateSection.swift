import CashlyDesignSystem
import SwiftUI

struct TransactionDateSection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            DatePicker(
                model.draft.date.formatted(.dateTime.weekday(.wide)), selection: $model.draft.date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .tint(.accentColor)
        } header: {
            Text("Data").sectionTitle()
        }
    }
}
