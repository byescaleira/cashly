import CashlyDesignSystem
import SwiftUI

struct TransactionSummarySection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Descreva a transação", text: $model.draft.summary, axis: .vertical)
        } header: {
            Text("Descrição").sectionTitle()
        }
    }
}
