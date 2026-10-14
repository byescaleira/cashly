import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct IntelligenceRow: View {
    @Environment(IntelligenceModel.self) private var intelligence: IntelligenceModel?

    var body: some View {
        if let intelligence, intelligence.isEnabled {
            SettingsRow("Intelligence", symbol: "cpu", color: RetroColor.sage.color) {
                IntelligenceScreen()
            }
        }
    }
}
