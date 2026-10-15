import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct MemojiGuideScreen: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        GuideSheet(
            index: 0, count: 1,
            primary: GuideAction("Done") { model.isShowingMemojiGuide = false },
            secondary: model.messagesURL.map { url in
                GuideAction("Open Messages") { openURL(url) }
            }
        ) {
            GuidePage(
                title: "Create Your Memoji",
                message:
                    "Memoji are made in the Messages app and then appear as stickers on the keyboard."
            ) {
                CashlyAnimationView(.memoji)
            } content: {
                GuideSteps([
                    GuideStep(
                        "message.fill", color: .companion, title: "Open a conversation",
                        detail: "Any chat in Messages works, nothing is sent."),
                    GuideStep(
                        "plus.circle.fill", color: .retroMustard, title: "Find the Memoji",
                        detail: "Tap the plus button, then Stickers, and make a new Memoji."),
                    GuideStep(
                        "face.smiling.inverse", color: .positive, title: "Come back to Cashly",
                        detail: "Choose Memoji again and pick your new sticker."),
                ])
            }
        }
    }
}
