import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TransactionSummarySection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            VStack(alignment: .leading, spacing: .spaceM) {
                TextField("Describe the transaction", text: $model.draft.summary, axis: .vertical)
                let tags = model.draft.summaryTags
                if !tags.isEmpty {
                    FlowLayout(spacing: .spaceXS) {
                        ForEach(tags) { tag in
                            TagChip(tag: tag) { model.dismissTag(tag) }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.snappy, value: model.draft.selectedTagIDs)
            Picker("Status", selection: $model.draft.status) {
                ForEach(TransactionStatus.allCases) { Text($0.summary).tag($0) }
            }
            .tint(model.draft.status.color)
        } header: {
            Text("Description").sectionTitle()
        }
    }
}

private struct TagChip: View {
    let tag: Tag
    let remove: () -> Void

    var body: some View {
        let color = Color(hex: tag.color)
        Button(action: remove) {
            Chip(tag.name, color: color, font: .subheadline.weight(.semibold))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tag \(tag.name)")
        .accessibilityHint("Tap to remove")
    }
}
