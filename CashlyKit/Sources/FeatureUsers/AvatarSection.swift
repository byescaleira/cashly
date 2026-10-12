import CashlyDesignSystem
import CashlyResource
import SwiftUI

struct AvatarSection: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
        } header: {
            Text("Foto").sectionTitle()
        } footer: {
            VStack(spacing: .space2XL) {
                Picker("Estilo", selection: $model.avatarStyle) {
                    ForEach(AvatarStyle.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.large)
                AvatarGrid(
                    photos: model.avatarStyle.photos, selection: $model.draft.photo)
            }
            .padding(.horizontal, -.spaceL)
        }
    }
}

private struct AvatarGrid: View {
    @Environment(\.appTint) private var appTint

    let photos: [String]
    @Binding var selection: String?

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: .spaceM)], spacing: .spaceM) {
            ForEach(photos, id: \.self) { photo in
                Button {
                    selection = photo
                } label: {
                    CashlyResourceImage.avatar(id: photo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .overlay {
                            if selection == photo {
                                Circle().stroke(appTint, lineWidth: 4).padding(-.space2XS)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Foto \(photo)")
                .accessibilityAddTraits(selection == photo ? .isSelected : [])
            }
        }
    }
}
