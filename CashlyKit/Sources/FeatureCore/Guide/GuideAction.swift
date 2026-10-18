import SwiftUI

public struct GuideAction {
    let title: LocalizedStringKey
    let isEnabled: Bool
    let perform: () -> Void
    let invite: SharedProfileInvite?
    let preview: String

    public init(_ title: LocalizedStringKey, isEnabled: Bool = true, perform: @escaping () -> Void)
    {
        self.title = title
        self.isEnabled = isEnabled
        self.perform = perform
        invite = nil
        preview = ""
    }

    public init(_ title: LocalizedStringKey, sharing invite: SharedProfileInvite, preview: String) {
        self.title = title
        isEnabled = true
        perform = {}
        self.invite = invite
        self.preview = preview
    }
}
