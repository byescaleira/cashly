import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct UserPhotoHeader: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.appTint) private var appTint
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
                AdaptiveStack(stackedAlignment: .center, spacing: .spaceXS) {
                    Chip(model.photoCaption, color: model.captionColor ?? appTint, shape: .capsule)
                        .contentTransition(.opacity)
                    if model.showsSharing {
                        Chip("Shared", color: .retroTeal, shape: .capsule)
                    }
                }
                .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceL)
            .textCase(nil)
            .accessibilityElement(children: .combine)
        }
    }
}
