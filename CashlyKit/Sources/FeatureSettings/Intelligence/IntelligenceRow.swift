import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct IntelligenceRow: View {
    @Environment(IntelligenceModel.self) private var intelligence: IntelligenceModel?
    @Environment(\.pro) private var pro

    var body: some View {
        if let intelligence, intelligence.isEnabled {
            SettingsRow(
                "Intelligence", symbol: "cpu", color: RetroColor.sage.color, value: pro.lockedValue
            ) {
                IntelligenceScreen()
            }
        }
    }
}
