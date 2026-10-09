import CashlyDesignSystem
import SwiftUI

struct CategoryNameSection: View {
    @Environment(CategoryEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Digite o nome da categoria", text: $model.draft.name)
        } header: {
            Text("Nome").sectionTitle()
        }
    }
}
