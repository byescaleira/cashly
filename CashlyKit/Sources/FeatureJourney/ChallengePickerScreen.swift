import CashlyDesignSystem
import CashlyGame
import FeatureCore
import SwiftUI

struct ChallengePickerScreen: View {
    @Environment(JourneyModel.self) private var journey
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var journey = journey
        NavigationStack {
            Form {
                Section {
                    Picker("Challenge", selection: $journey.draft.kind) {
                        ForEach(Challenge.Kind.allCases, id: \.self) { kind in
                            ChallengeKindRow(kind: kind).tag(kind)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } footer: {
                    Text(journey.draftFooter)
                }
                if journey.draft.kind.needsCategory {
                    Section {
                        Picker("Category", selection: $journey.draft.categoryID) {
                            ForEach(journey.categories) { category in
                                Text(category.name).tag(Optional(category.id))
                            }
                        }
                    }
                }
                if journey.draft.kind == .cap {
                    Section("Limit") {
                        CurrencyField(amount: $journey.draft.limit)
                            .font(.amountRow)
                    }
                }
            }
            .formStyle(.grouped)
            .fontDesign(.rounded)
            .navigationTitle("New Challenge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start", systemImage: "checkmark") {
                        Task { await journey.startChallenge() }
                    }
                    .disabled(journey.draft.challenge == nil)
                }
            }
        }
    }
}

private struct ChallengeKindRow: View {
    @Environment(\.appTint) private var appTint
    let kind: Challenge.Kind

    var body: some View {
        HStack(spacing: .spaceM) {
            SymbolBadge(kind.symbol, color: appTint, size: .badgeM)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(kind.title).font(.rowTitle)
                Text(kind.duration).font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Chip("+\(kind.xp) XP", color: appTint).fixedSize()
        }
    }
}
