#if DEBUG
    import CashlyDomain
    import CashlyMock
    import FeatureCore
    import FeatureSharing
    import SwiftUI

    #Preview("Perfil compartilhado") {
        NavigationStack { SharedProfileScreen(profileID: SampleData.owner.id) }
            .cashlyPreview()
    }

    #Preview("Convite") {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                SharingInviteScreen(profile: User(id: "home", name: "Home", isShared: true))
            }
            .cashlyPreview()
    }

    #Preview("Entrou") {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                SharingJoinedScreen(joined: SharingModel.JoinedProfile(id: "home", title: "Home"))
            }
            .cashlyPreview()
    }
#endif
