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
                selection: Binding(
                    get: { YearMonth(model.draft.date) }, set: { model.draft.date = $0.startDate }))
        } header: {
            Text("Mês").sectionTitle()
        }
    }
}
