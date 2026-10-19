import FeatureCore
import FeatureSharing
import SwiftUI

struct SharingPresenter: ViewModifier {
    @Environment(SharingModel.self) private var sharing
    @Environment(\.scenePhase) private var scenePhase
    @State private var id = UUID()

    func body(content: Content) -> some View {
        @Bindable var sharing = sharing
        let isPresenter = sharing.presenterID == id
        content
            .sheet(item: isPresenter ? $sharing.inviting : .constant(nil)) {
                SharingInviteScreen(profile: $0)
            }
            .sheet(item: isPresenter ? $sharing.joined : .constant(nil)) {
                SharingJoinedScreen(joined: $0)
            }
            .errorAlert(isPresenter ? $sharing.acceptError : .constant(nil))
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active { sharing.claimPresentation(id) }
            }
            .onAppear { sharing.claimIfUnclaimed(id) }
            .onChange(of: sharing.presenterID == nil) { _, isFree in
                if isFree { sharing.claimIfUnclaimed(id) }
            }
            .onDisappear { sharing.releasePresentation(id) }
    }
}
