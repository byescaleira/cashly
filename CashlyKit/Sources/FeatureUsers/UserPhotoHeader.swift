import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct UserPhotoHeader: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Section {
        } header: {
            VStack(spacing: .spaceM) {
                ProfileAvatar(photo: model.draft.photo, initials: model.initials, size: .medallion)
                    .id(model.draft.photo)
                    .transition(
                        reduceMotion ? .opacity : .scale(scale: 0.8).combined(with: .opacity)
                    )
                    .animation(reduceMotion ? nil : .bouncy, value: model.draft.photo)
                Text(verbatim: model.displayName)
                    .font(.titleMedium)
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Chip(model.photoCaption, color: model.captionTint, shape: .capsule)
                    .textCase(.uppercase)
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceL)
            .textCase(nil)
            .accessibilityElement(children: .combine)
        }
    }
}
