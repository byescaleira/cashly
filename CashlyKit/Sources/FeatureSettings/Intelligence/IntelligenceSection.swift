import FeatureCore
import SwiftUI

struct IntelligenceSection: View {
    @Environment(IntelligenceModel.self) private var intelligence: IntelligenceModel?

    var body: some View {
        if intelligence != nil {
            Section {
                NavigationLink {
                    IntelligenceScreen()
                } label: {
                    Label("Inteligência", systemImage: "cpu")
                }
            } footer: {
                Text("Modelos treinados no aparelho para previsões e sugestões de categoria.")
            }
        }
    }
}
