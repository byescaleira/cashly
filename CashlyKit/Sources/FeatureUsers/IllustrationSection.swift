import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct IllustrationSection: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.shop) private var shop
    let section: ProfileIllustration.Section

    var body: some View {
        let access = model.access(to: section, in: shop)
        Section {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 70), spacing: .spaceM)], spacing: .spaceM
            ) {
                ForEach(section.illustrations) {
                    IllustrationChoice(illustration: $0, access: access)
                }
            }
            .padding(.vertical, .spaceS)
        } header: {
            HStack(alignment: .lastTextBaseline) {
                Text(verbatim: section.title).sectionTitle()
                Spacer()
                PackAccessButton(access: access)
            }
            .textCase(nil)
        } footer: {
            if access == .pro {
                Text("Exclusive to Cashly Pro.")
            } else if access.lockedItem != nil {
                Text("Available in the Journey shop.")
            }
        }
    }
}

private struct IllustrationChoice: View {
    @Environment(UserEditorModel.self) private var model
    @Environment(\.shop) private var shop
    @Environment(\.appTint) private var appTint
    let illustration: ProfileIllustration
    let access: PackAccess

    var body: some View {
        let isSelected = model.isSelected(illustration)
        Button {
            model.choose(illustration, in: shop)
        } label: {
            ProfileAvatar(photo: .illustration(illustration.id), initials: "", size: .badgeXL)
                .opacity(access.isLocked ? .opacityStrong : 1)
                .overlay {
                    if isSelected {
                        Circle().stroke(appTint, lineWidth: 3).padding(-.space2XS)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if access.isLocked { LockBadge() }
                }
                .frame(minWidth: .rowHeight, minHeight: .rowHeight)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(illustration.name)
        .accessibilityValue(Text(verbatim: access.lockValue ?? ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
