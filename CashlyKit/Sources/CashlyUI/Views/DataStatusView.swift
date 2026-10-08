import CashlyDomain
import CashlyPresentation
import SwiftUI

struct DataStatusView: View {
    @Environment(MainViewModel.self) private var main
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section
    var body: some View {
        if main.pendingReferences > 0 {
            Section {
                Label(
                    "Há registros incompletos aguardando sincronização. Os totais exibidos consideram apenas os registros disponíveis.",
                    systemImage: "icloud.and.arrow.down"
                )
                .foregroundStyle(.orange)
                Button("Atualizar dados") { Task { await main.load() } }
            }
        }
        if !main.conflicts.isEmpty {
            Section("Conflitos de orçamento") {
                Text(
                    "Valores planejados em conflito ficam fora dos totais até você escolher o orçamento que deve prevalecer."
                )
                ForEach(main.conflicts) { conflict in
                    Button {
                        open(
                            .budgetConflict(categoryID: conflict.categoryID, month: conflict.month),
                            in: section)
                    } label: {
                        Label(
                            main.allCategories.first { $0.id == conflict.categoryID }?.name
                                ?? "Orçamento",
                            systemImage: "exclamationmark.triangle")
                    }
                }
            }
        }
    }
}
