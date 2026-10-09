import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct ParticipantsSection: View {
    @Environment(TransactionEditorModel.self) private var model

    var body: some View {
        @Bindable var model = model
        if !model.draft.participants.isEmpty {
            Section {
                AdaptiveStack(spacing: 8) {
                    Text("Modo de divisão").frame(maxWidth: .infinity, alignment: .leading)
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
                            .foregroundStyle(Color.accentColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .surface(
                                tint: .accentColor.opacity(0.2), in: .capsule, interactive: true)
                    }
                }
            } header: {
                Text("Participantes").sectionTitle()
            } footer: {
                Text(model.draft.splitMode?.description ?? "")
            }
            Section {
                ForEach($model.draft.participants) { $participant in
                    ParticipantRow(participant: $participant, amount: model.draft.amount)
                        .swipeActions {
                            Button("Remover", systemImage: "trash", role: .destructive) {
                                model.removeParticipant(id: participant.id)
                            }
                        }
                }
            }
        }
    }
}
