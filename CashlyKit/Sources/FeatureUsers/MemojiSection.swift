import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct MemojiSection: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            HStack(spacing: .spaceM) {
                ProfileAvatar(photo: model.preview(for: .memoji), initials: model.initials)
                    .accessibilityHidden(true)
                MemojiField(isActive: $model.isPickingMemoji) { model.capture($0) }
            }
            .padding(.vertical, .space2XS)
            Button {
                model.isShowingMemojiGuide = true
            } label: {
                IconRow(
                    "Create Memoji", detail: "Made in the Messages app", symbol: "face.smiling",
                    color: .companion)
            }
            .buttonStyle(.plain)
        } header: {
            Text("Memoji").sectionTitle()
        } footer: {
            Text(verbatim: model.memojiFooter)
        }
    }
}
