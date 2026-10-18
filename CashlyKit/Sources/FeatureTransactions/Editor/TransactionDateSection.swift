import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct TransactionDateSection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            DatePicker(
                model.draft.date.formatted(.dateTime.weekday(.wide).locale(.app)),
                selection: $model.draft.date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
        } header: {
            Text("Date").sectionTitle()
        }
    }
}
