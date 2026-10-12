import CashlyDomain
import SwiftUI

struct CurrencySection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Picker("Currency", selection: $settings.currency) {
                ForEach(CurrencySetting.supported, id: \.self) {
                    Text(settings.currencyName($0)).tag($0)
                }
            }
            .labelsHidden()
            .pickerStyle(.inline)
        } footer: {
            Text(
                "Amounts aren't converted: changing the currency changes the symbol shown and the currency of new records."
            )
        }
    }
}
