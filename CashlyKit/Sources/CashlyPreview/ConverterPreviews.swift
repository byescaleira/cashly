#if DEBUG
    import CashlyDomain
    import FeatureConverter
    import FeatureCore
    import Foundation
    import SwiftUI

    #Preview("Conversor") {
        NavigationStack {
            ModelHost(ConverterModel(rates: PreviewRates())) { ConverterScreen() }
        }
        .cashlyPreview()
    }

    private struct PreviewRates: ExchangeRateProviding {
        func table(base: String, on date: Date?) async throws -> ExchangeTable {
            ExchangeTable(
                base: base, day: ExchangeTable.day(for: .now),
                rates: [
                    "BRL": Decimal(string: "5.19") ?? 5, "USD": 1,
                    "EUR": Decimal(string: "0.92") ?? 1,
                ],
                source: .currencyAPI)
        }

        func currencies() async throws -> [String] {
            ["BRL", "EUR", "JPY", "USD"]
        }
    }
#endif
