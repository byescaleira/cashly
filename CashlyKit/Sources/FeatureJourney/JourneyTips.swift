import FeatureCore
import SwiftUI
import TipKit

struct NoSpendDayTip: Tip {
    var title: Text { Text("Quiet day? Keep the streak") }
    var message: Text? {
        Text("Mark \"I didn't spend today\" and the flame keeps going without a transaction.")
    }
    var image: Image? { Image(systemName: "hand.raised") }
    var rules: [Rule] {
        #Rule(CashlyTips.journeyOpened) { $0.donations.count >= 2 }
    }
}

struct ChallengeTip: Tip {
    @Parameter static var hasChallenge: Bool = false

    var title: Text { Text("Pick a challenge for the month") }
    var message: Text? {
        Text("Spend less in a category or stay under a limit and earn up to 300 XP.")
    }
    var image: Image? { Image(systemName: "flag") }
    var rules: [Rule] {
        #Rule(Self.$hasChallenge) { $0 == false }
        #Rule(CashlyTips.journeyOpened) { $0.donations.count >= 3 }
    }
}
