import CashlyDesignSystem
import SwiftUI

struct CategoryNameSection: View {
    @Environment(CategoryEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Enter the category name", text: $model.draft.name)
        } header: {
            Text("Name").sectionTitle()
        }
    }
}
