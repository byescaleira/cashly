import CashlyDesignSystem
import SwiftUI

struct InstallmentSection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            Toggle("Parcelar", isOn: $model.draft.installmentIsOn)
                .tint(.positive)
            if model.draft.installmentIsOn {
                Picker("Número de parcelas", selection: $model.draft.installmentPlan) {
                    ForEach(1...21, id: \.self) { Text("\($0)x").tag($0) }
                }
            }
        } header: {
            Text("Parcelamento").sectionTitle()
        }
    }
}
