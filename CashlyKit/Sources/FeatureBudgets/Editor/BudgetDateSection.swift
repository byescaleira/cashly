import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct BudgetDateSection: View {
    @Environment(BudgetEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            MonthPicker(
                selection: $model.month, unavailable: model.takenMonths,
                unavailableTitle: model.takenMonthTitle)
        } header: {
            Text("Month").sectionTitle()
        } footer: {
            if let message = model.monthMessage {
                Text(message).foregroundStyle(model.isMonthTaken ? Color.negative : .secondary)
            }
        }
    }
}
