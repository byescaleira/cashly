import FeatureCore
import SwiftUI
import TipKit

public struct ClaudeCodeTipView: View {
    let isConnected: Bool

    public init(isConnected: Bool) {
        self.isConnected = isConnected
    }

    public var body: some View {
        TipView(ClaudeCodeTip())
            .tipBackground(.clear)
            .onChange(of: isConnected, initial: true) { ClaudeCodeTip.isConnected = $1 }
    }
}

private struct ClaudeCodeTip: Tip {
    @Parameter static var isConnected: Bool = false

    var title: Text { Text("Connect Claude Code") }
    var message: Text? {
        Text(
            "Let Claude read your months and send transactions from your computer, always with your approval."
        )
    }
    var image: Image? { Image(systemName: "terminal") }
    var rules: [Rule] {
        #Rule(Self.$isConnected) { $0 == false }
        #Rule(CashlyTips.transactionSaved) { $0.donations.count >= 10 }
    }
}
