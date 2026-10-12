import CashlyDesignSystem
import SwiftUI

struct TagNameSection: View {
    @Environment(TagEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Enter the tag name", text: $model.draft.name)
        } header: {
            Text("Name").sectionTitle()
        }
    }
}
