import CashlyDesignSystem
import SwiftUI

struct TagNameSection: View {
    @Environment(TagEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Digite o nome da tag", text: $model.draft.name)
        } header: {
            Text("Nome").sectionTitle()
        }
    }
}
