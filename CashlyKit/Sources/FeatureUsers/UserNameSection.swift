import CashlyDesignSystem
import SwiftUI

struct UserNameSection: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Enter the user's name", text: $model.draft.name)
        } header: {
            Text("First and last name").sectionTitle()
        }
    }
}
