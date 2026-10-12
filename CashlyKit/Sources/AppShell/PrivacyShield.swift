import CashlyDesignSystem
import FeatureCore
import FeatureSettings
import SwiftUI

struct PrivacyShield: ViewModifier {
    @Environment(SettingsModel.self) private var settings
    @Environment(AppLockModel.self) private var lock
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .redacted(reason: settings.isDiscreet ? .privacy : [])
            .overlay {
                if lock.isLocked || (settings.locksApp && scenePhase != .active) {
                    LockedView().transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: lock.isLocked)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background: if settings.locksApp { lock.lock() }
                case .active: if lock.isLocked { Task { await lock.unlock() } }
                default: break
                }
            }
            .task { if lock.isLocked { await lock.unlock() } }
    }
}

private struct LockedView: View {
    @Environment(AppLockModel.self) private var lock

    var body: some View {
        VStack(spacing: .spaceL) {
            CashlyAnimationView(.launch, loops: true).frame(maxWidth: 220)
            if lock.isLocked {
                Button {
                    Task { await lock.unlock() }
                } label: {
                    Label("Unlock", systemImage: "lock.open").frame(maxWidth: .infinity)
                }
                .prominentButton()
                .frame(maxWidth: 220)
                .disabled(lock.isAuthenticating)
            }
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
    }
}
