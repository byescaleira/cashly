import CashlyDesignSystem
import SwiftUI

struct UserNameSection: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Enter the profile's name", text: $model.draft.name)
        } header: {
            Text("Name").sectionTitle()
        }
    }
}
