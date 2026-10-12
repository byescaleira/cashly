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
                    "Última atualização",
                    value: info.updateDate.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Transações", value: info.sampleCount.formatted())
            }
        } footer: {
            Text(kind.summary)
        }
    }
}
