import CashlyDomain
import SwiftUI

struct CurrencySection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            Picker("Valores em", selection: $settings.currency) {
                ForEach(CurrencySetting.supported, id: \.self) {
                    Text(settings.currencyName($0)).tag($0)
                }
            }
        } header: {
            Text("Moeda")
        } footer: {
            Text(
                "Os valores não são convertidos: trocar a moeda muda o símbolo exibido e a moeda dos novos registros."
            )
        }
    }
}
