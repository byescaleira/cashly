import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ParticipantsSection: View {
    @Environment(\.appTint) private var appTint

    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        if !model.draft.participants.isEmpty {
            Section {
                AdaptiveStack(spacing: .spaceS) {
                    Text("Split Mode").frame(maxWidth: .infinity, alignment: .leading)
                    Menu {
                        Picker(selection: $model.draft.splitMode) {
                            ForEach(TransactionSplitMode.allCases) {
                                Text($0.summary).tag(Optional($0))
                            }
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        Text(model.draft.splitMode?.summary.uppercased() ?? "")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(appTint)
                            .padding(.vertical, .spaceS)
                            .padding(.horizontal, .spaceM)
                            .surface(
                                tint: appTint.opacity(.opacityTint), in: .capsule, interactive: true
                            )
                    }
                }
            } header: {
                Text("Participants").sectionTitle()
            } footer: {
                Text(model.draft.splitMode?.description ?? "")
            }
            Section {
                ForEach($model.draft.participants) { $participant in
                    ParticipantRow(participant: $participant, amount: model.draft.amount)
                        .swipeActions {
                            Button("Remove", systemImage: "trash", role: .destructive) {
                                model.removeParticipant(id: participant.id)
                            }
                        }
                }
            }
        }
    }
}
