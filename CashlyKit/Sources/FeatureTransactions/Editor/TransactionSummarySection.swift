import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct TransactionSummarySection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Descreva a transação", text: $model.draft.summary, axis: .vertical)
                let tags = model.draft.summaryTags
                if !tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(tags) { tag in
                            TagChip(tag: tag) { model.dismissTag(tag) }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.snappy, value: model.draft.selectedTagIDs)
            Picker("Situação", selection: $model.draft.status) {
                ForEach(TransactionStatus.allCases) { Text($0.summary).tag($0) }
            }
            .tint(model.draft.status.color)
        } header: {
            Text("Descrição").sectionTitle()
        }
    }
}

private struct TagChip: View {
    let tag: Tag
    let remove: () -> Void

    var body: some View {
        let color = Color(hex: tag.color)
        Button(action: remove) {
            Text(tag.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(color.opacity(0.2), in: .rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tag \(tag.name)")
        .accessibilityHint("Toque para remover")
    }
}
