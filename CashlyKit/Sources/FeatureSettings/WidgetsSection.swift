import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct WidgetsSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        @Bindable var settings = settings
        Section {
            Picker("One Budget shows", selection: $settings.widgetCategoryID) {
                Text("Nothing yet").tag(String?.none)
                ForEach(finance.budgets.sorted { $0.category.name < $1.category.name }, id: \.id) {
                    Label($0.category.name, systemImage: $0.category.icon).tag(
                        String?.some($0.category.id))
                }
            }
            .pickerStyle(.inline)
        } header: {
            Text("One Budget")
        } footer: {
            Text(
                "The One Budget widget follows the category you pick here, for every copy of it on your Home Screen."
            )
        }
    }
}
