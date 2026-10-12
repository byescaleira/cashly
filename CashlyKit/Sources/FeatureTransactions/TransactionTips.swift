import FeatureCore
import SwiftUI
import TipKit

struct SwipeToDeleteTip: Tip {
    var title: Text { Text("Swipe to delete") }
    var message: Text? { Text("Swipe a transaction to the left to delete it. Tap it to edit.") }
    var image: Image? { Image(systemName: "hand.draw") }
    var rules: [Rule] {
        #Rule(CashlyTips.transactionSaved) { $0.donations.count >= 3 }
    }
}

struct SplitTip: Tip {
    var title: Text { Text("Split with others") }
    var message: Text? {
        Text("Choose who shares this expense and Cashly divides the amount for you.")
    }
    var image: Image? { Image(systemName: "person.2.badge.plus") }
    var rules: [Rule] {
        #Rule(CashlyTips.transactionSaved) { $0.donations.count >= 2 }
    }
}
