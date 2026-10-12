import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ModelSection: View {
    @Environment(IntelligenceModel.self) private var intelligence
    let kind: CashlyIntelligence

    var body: some View {
        Section {
            IconRow(verbatim: kind.name, symbol: kind.icon, color: kind.color)
            if let info = intelligence.info(for: kind) {
                LabeledContent(
                    "Last Updated",
                    value: info.updateDate.formatted(
                        Date.FormatStyle(date: .abbreviated, time: .shortened, locale: .app)))
                LabeledContent(
                    "Transactions", value: info.sampleCount.formatted(.number.locale(.app)))
            }
        } footer: {
            Text(kind.summary)
        }
    }
}
