import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct SharedProfileSection: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        if model.createsShared {
            NewSharedProfileSection()
        } else if model.showsPeople {
            SharedPeopleSection()
        }
    }
}

private struct NewSharedProfileSection: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.appTint) private var appTint

    var body: some View {
        @Bindable var model = model
        Section {
            IconRow(
                "Everyone on their own device",
                detail: "After saving, invite by Messages, Mail or AirDrop.",
                symbol: "person.2", color: appTint)
            if model.canCopyCategories {
                Toggle(isOn: $model.draft.copiesCategories) {
                    IconRow(
                        verbatim: model.copyCategoriesTitle, detail: model.copyCategoriesDetail,
                        symbol: "square.grid.2x2", color: .companion)
                }
            }
        } header: {
            Text("Shared Profile").sectionTitle()
        } footer: {
            Text(
                "Everyone you invite sees and edits this profile. Your other profiles stay private, and sharing is free."
            )
        }
        if model.showsAccountNotice { ICloudNoticeSection() }
    }
}

private struct ICloudNoticeSection: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            IconRow(
                "Sign in to iCloud",
                detail:
                    "Shared profiles travel through iCloud. Sign in on this device and try again.",
                symbol: "icloud.slash", color: .warning)
            if let url = model.settingsURL {
                Button("Open Settings") { openURL(url) }
            }
        }
    }
}

private struct SharedPeopleSection: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            DisclosureLink {
                RouteView(.sharedProfile(id: model.draft.id))
            } label: {
                IconRow(
                    "People", detail: "Invite, see who joined, or leave.", symbol: "person.2",
                    color: appTint)
            }
        } header: {
            Text("Shared Profile").sectionTitle()
        }
    }
}
