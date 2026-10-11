import CashlyDomain
import SwiftUI

struct CurrencySection: View {
    @Environment(SettingsModel.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Section {
            LabeledContent("Moeda") {
                Picker("Moeda", selection: $settings.currency) {
                    ForEach(CurrencySetting.supported, id: \.self) {
                        Text(settings.currencyName($0)).tag($0)
                    }
                }
                .labelsHidden()
            }
        } footer: {
            Text(
                "Os valores não são convertidos: trocar a moeda muda o símbolo exibido e a moeda dos novos registros."
            )
        }
    }
}
