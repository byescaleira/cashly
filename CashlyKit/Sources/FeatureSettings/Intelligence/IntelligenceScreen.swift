import CashlyDomain
import FeatureCore
import SwiftUI

struct IntelligenceScreen: View {
    @Environment(IntelligenceModel.self) private var intelligence

    var body: some View {
        @Bindable var intelligence = intelligence
        SettingsPage("Inteligência") {
            DeviceSection()
            if intelligence.isStale {
                Text("O histórico mudou. Treine novamente para atualizar as sugestões.")
                    .foregroundStyle(Color.secondary)
            }
            ForEach(CashlyIntelligence.allCases) { ModelSection(kind: $0) }
            TrainingSection()
        }
        .errorAlert($intelligence.error)
    }
}
