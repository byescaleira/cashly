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
            VStack(spacing: 32) {
                Picker("Estilo", selection: $model.avatarStyle) {
                    ForEach(AvatarStyle.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.large)
                AvatarGrid(
                    photos: model.avatarStyle.photos, selection: $model.draft.photo)
            }
            .padding(.horizontal, -16)
        }
    }
}

private struct AvatarGrid: View {
    @Environment(\.appTint) private var appTint

    let photos: [String]
    @Binding var selection: String?

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 14)], spacing: 14) {
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
                                Circle().stroke(appTint, lineWidth: 4).padding(-4)
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
