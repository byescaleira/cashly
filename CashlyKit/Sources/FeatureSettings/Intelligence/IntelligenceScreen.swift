import CashlyDomain
import FeatureCore
import SwiftUI

struct IntelligenceScreen: View {
    @Environment(IntelligenceModel.self) private var intelligence

    var body: some View {
        @Bindable var intelligence = intelligence
        SettingsPage("Intelligence") {
            DeviceSection()
            if intelligence.isStale {
                Text("Your history changed. Train again to update the suggestions.")
                    .foregroundStyle(Color.secondary)
            }
            ForEach(CashlyIntelligence.allCases) { ModelSection(kind: $0) }
            TrainingSection()
        }
        .errorAlert($intelligence.error)
    }
}
