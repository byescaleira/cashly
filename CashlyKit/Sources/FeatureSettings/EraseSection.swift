import CashlyDesignSystem
import SwiftUI

struct EraseSection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        @Bindable var data = data
        Section {
            Button(role: .destructive) {
                data.isConfirmingErase = true
            } label: {
                IconRow(
                    "Delete All Data", symbol: "trash", color: .negative,
                    titleColor: .negative)
            }
            .confirmationDialog(
                "Delete All Data?", isPresented: $data.isConfirmingErase,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) { Task { await data.eraseAll() } }
            } message: {
                Text(
                    "Users, categories, tags, budgets and transactions will be deleted. With iCloud on, the data also leaves your other devices. This can't be undone."
                )
            }
        }
    }
}
