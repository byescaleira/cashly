import CashlyDesignSystem
import SwiftUI

struct InstallmentSection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            Toggle("Pay in Installments", isOn: $model.draft.installmentIsOn)
                .tint(.positive)
            if model.draft.installmentIsOn {
                Picker("Number of Installments", selection: $model.draft.installmentPlan) {
                    ForEach(1...21, id: \.self) { Text("\($0)x").tag($0) }
                }
            }
        } header: {
            Text("Installments").sectionTitle()
        }
    }
}
