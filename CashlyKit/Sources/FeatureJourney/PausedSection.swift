import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct PausedSection: View {
    @Environment(\.pro) private var pro

    var body: some View {
        if !pro.canWrite {
            Section {
                Button {
                    pro.present()
                } label: {
                    IconRow(
                        "Journey Paused",
                        detail:
                            "Your progress is kept. Subscribe to keep earning XP, streaks and achievements.",
                        symbol: "pause.circle", color: .retroMustard)
                }
            }
        }
    }
}
