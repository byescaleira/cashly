import CashlyDesignSystem
import SwiftUI

extension View {
    public func editorLifecycle(
        _ status: EditorStatus, selecting userID: String? = nil,
        load: @escaping @MainActor () async -> Void
    ) -> some View {
        modifier(EditorLifecycle(status: status, userID: userID, load: load))
    }
}

private struct EditorLifecycle: ViewModifier {
    @Environment(SessionModel.self) private var session
    @Environment(\.close) private var close
    let status: EditorStatus
    let userID: String?
    let load: @MainActor () async -> Void

    func body(content: Content) -> some View {
        @Bindable var status = status
        content
            .task { await load() }
            .dismissKeyboardOnScroll()
            .onChange(of: status.isSaved) {
                guard status.isSaved else { return }
                close()
                if let userID {
                    Task { await session.selectUser(id: userID) }
                } else {
                    session.reload()
                }
            }
            .errorAlert($status.error)
            .disabled(status.isLocked)
            .interactiveDismissDisabled(status.isBusy)
            .environment(\.isLoading, status.isBusy)
    }
}
