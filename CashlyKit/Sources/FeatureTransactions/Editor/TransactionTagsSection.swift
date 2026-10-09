import SwiftUI

struct TransactionTagsSection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        if !model.draft.tags.isEmpty {
            Section("Tags") {
                ForEach(model.draft.tags) { tag in
                    Toggle(
                        tag.name,
                        isOn: Binding(
                            get: { model.isTagSelected(tag) },
                            set: { model.setTag(tag, selected: $0) }))
                }
                if !model.draft.suggestedTags.isEmpty {
                    Text("Sugestões pela descrição")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                    ForEach(model.draft.suggestedTags) { tag in
                        Button("Adicionar \(tag.name)") { model.setTag(tag, selected: true) }
                    }
                }
            }
        }
    }
}
