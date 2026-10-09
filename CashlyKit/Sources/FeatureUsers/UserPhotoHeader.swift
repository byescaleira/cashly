import CashlyDesignSystem
import CashlyResource
import SwiftUI

struct UserPhotoHeader: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        Section {
        } header: {
            CashlyResourceImage.avatar(id: model.draft.photo)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .background(.subtleFill)
                .clipShape(.circle)
                .overlay(alignment: .bottomTrailing) {
                    Button("Sortear foto", systemImage: "repeat") { model.shufflePhoto() }
                        .labelStyle(.iconOnly)
                        .font(.system(size: 20, weight: .bold))
                        .prominentButton()
                }
                .frame(maxWidth: .infinity)
        }
    }
}
