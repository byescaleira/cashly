import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct DataStatusSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    public init() {}

    public var body: some View {
        if finance.pendingReferences > 0 {
            Section {
                Label(
                    "Some records are still waiting to sync. Totals only include the records available.",
                    systemImage: "icloud.and.arrow.down"
                )
                .foregroundStyle(.warning)
                Button("Refresh Data") { session.reload() }
            }
        }
        if !finance.conflicts.isEmpty {
            Section {
                ForEach(finance.conflicts) { conflict in
                    Button {
                        open(
                            .budgetConflict(categoryID: conflict.categoryID, month: conflict.month),
                            in: section)
                    } label: {
                        Label(
                            finance.allCategories.first { $0.id == conflict.categoryID }?.name
                                ?? String(appLocalized: "Budget"),
                            systemImage: "exclamationmark.triangle")
                    }
                }
            } header: {
                Text("Budget conflicts").sectionTitle()
            } footer: {
                Text(
                    "Conflicting planned amounts stay out of the totals until you choose which budget to keep."
                )
            }
        }
    }
}
