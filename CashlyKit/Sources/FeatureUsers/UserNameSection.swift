import CashlyDesignSystem
import SwiftUI

struct UserNameSection: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Digite o nome do usuário", text: $model.draft.name)
        } header: {
            Text("Nome e sobrenome").sectionTitle()
        }
    }
}
