import CashlyDesignSystem
import CashlyWeb
import FeatureCore
import SwiftUI

struct WebDisconnectScreen: View {
    @Environment(WebSharingModel.self) private var web
    let session: WebSession

    var body: some View {
        @Bindable var web = web
        GuideSheet(
            index: 0, count: 1, isWorking: web.disconnectingID == session.id,
            primary: GuideAction("Disconnect") { Task { await web.disconnect(session) } },
            secondary: GuideAction("Cancel") { web.confirmingDisconnect = nil }
        ) {
            GuidePage(
                title: "Disconnect This Computer?",
                message:
                    "The summary is deleted from the bridge and that browser goes back to the QR code. Scan it again to reconnect."
            ) {
                CashlyAnimationView(.privacy)
            }
        }
        .tint(Color.negative)
        .errorAlert($web.error)
    }
}
