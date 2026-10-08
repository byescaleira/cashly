import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI

struct DataStatusView: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    var body: some View {
        if finance.pendingReferences > 0 {
            Section {
                Label(
                    "Há registros incompletos aguardando sincronização. Os totais exibidos consideram apenas os registros disponíveis.",
                    systemImage: "icloud.and.arrow.down"
                )
                .foregroundStyle(.orange)
                Button("Atualizar dados") { session.reload() }
            }
        }
        if !finance.conflicts.isEmpty {
            Section("Conflitos de orçamento") {
                Text(
                    "Valores planejados em conflito ficam fora dos totais até você escolher o orçamento que deve prevalecer."
                )
                ForEach(finance.conflicts) { conflict in
                    Button {
                        open(
                            .budgetConflict(categoryID: conflict.categoryID, month: conflict.month),
                            in: section)
                    } label: {
                        Label(
                            finance.allCategories.first { $0.id == conflict.categoryID }?.name
                                ?? "Orçamento",
                            systemImage: "exclamationmark.triangle")
                    }
                }
            }
        }
    }
}
