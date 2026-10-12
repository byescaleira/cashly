import CashlyDesignSystem
import SwiftUI

public struct ExampleMonthSummary: View {
    public init() {}

    public var body: some View {
        GuideExample {
            ExampleHeadline(
                chip: Date.now.formatted(.dateTime.month(.wide)),
                value: 3_240.0.formatted(.appCurrency), detail: "disponível no mês")
            Divider()
            ExampleRow(
                "Entradas", value: 6_500.0.formatted(.appCurrency), valueColor: .positive)
            ExampleRow("Saídas", value: 3_260.0.formatted(.appCurrency), valueColor: .negative)
        }
    }
}
