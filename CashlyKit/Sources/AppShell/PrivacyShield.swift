import CashlyDesignSystem
import FeatureCore
import FeatureSettings
import SwiftUI

public struct PrivacyShield: ViewModifier {
    @Environment(SettingsModel.self) private var settings
    @Environment(AppLockModel.self) private var lock
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public func body(content: Content) -> some View {
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
        VStack(spacing: .spaceXL) {
            Spacer(minLength: 0)
            GuidePage(
                title: "Cashly is locked",
                message: "Your finances stay hidden until you unlock."
            ) {
                CashlyAnimationView(.launch, loops: true)
            }
            Spacer(minLength: 0)
            if lock.isLocked {
                Button {
                    Task { await lock.unlock() }
                } label: {
                    ZStack {
                        Text(unlockTitle).opacity(lock.isAuthenticating ? 0 : 1)
                        if lock.isAuthenticating { ProgressView() }
                    }
                }
                .primaryButton()
                .disabled(lock.isAuthenticating)
            }
        }
        .frame(maxWidth: 440)
        .padding(.spaceXL)
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
    }

    private var unlockTitle: LocalizedStringKey {
        lock.biometry == .none ? "Unlock with Passcode" : "Unlock with \(lock.biometry.title)"
    }
}
