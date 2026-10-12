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
                            Label(kind.title, systemImage: kind.symbol).tag(kind)
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
