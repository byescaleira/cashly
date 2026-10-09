import CashlyDomain
import FeatureCore
import SwiftUI

struct ModelSection: View {
    @Environment(IntelligenceModel.self) private var intelligence
    let kind: CashlyIntelligence

    var body: some View {
        Section {
            Label(kind.name, systemImage: kind.icon).foregroundStyle(kind.color)
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
