import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct PhotoStyleSection: View {
    @Environment(UserEditorModel.self) private var model

    var body: some View {
        Section {
            HStack(alignment: .top, spacing: .spaceM) {
                ForEach(PhotoStyle.allCases) { PhotoStyleChoice(style: $0) }
            }
            .padding(.vertical, .spaceS)
            .sensoryFeedback(.selection, trigger: model.style)
        } header: {
            Text("Photo").sectionTitle()
        } footer: {
            Text(
                "Initials follow the name. A symbol or an illustration stays the same when the name changes."
            )
        }
    }
}

private struct PhotoStyleChoice: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.appTint) private var appTint
    let style: PhotoStyle

    var body: some View {
        let isSelected = model.style == style
        Button {
            model.select(style)
        } label: {
            VStack(spacing: .spaceS) {
                ProfileAvatar(photo: model.preview(for: style), initials: model.initials)
                    .accessibilityHidden(true)
                Text(verbatim: style.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                SelectionMark(isSelected: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceM)
            .background(.subtleFill, in: .rect(cornerRadius: .radiusM))
            .overlay {
                RoundedRectangle(cornerRadius: .radiusM, style: .continuous)
                    .stroke(isSelected ? appTint : .clear, lineWidth: 3)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
