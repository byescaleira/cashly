import CashlyDomain
import FeatureCore
import SwiftUI

public struct IntelligenceScreen: View {
    @Environment(IntelligenceModel.self) private var intelligence

    public init() {}

    public var body: some View {
        @Bindable var intelligence = intelligence
        List {
            DeviceSection()
            if intelligence.isStale {
                Text("O histórico mudou. Treine novamente para atualizar as sugestões.")
                    .foregroundStyle(Color.secondary)
            }
            ForEach(CashlyIntelligence.allCases) { ModelSection(kind: $0) }
            TrainingSection()
        }
        .fontDesign(.rounded)
        .navigationTitle("Inteligência")
        .toolbar { ToolbarItem { UserMenu() } }
        .errorAlert($intelligence.error)
    }
}
