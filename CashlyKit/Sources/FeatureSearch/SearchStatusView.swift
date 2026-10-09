import SwiftUI

struct SearchStatusView: View {
    @Environment(SearchModel.self) private var search

    var body: some View {
        if search.term.isEmpty {
            ContentUnavailableView(
                "Buscar no Cashly", systemImage: "magnifyingglass",
                description: Text("Procure por descrição, categoria ou tag em todos os períodos."))
        } else if !search.hasResults && !search.isSearching {
            ContentUnavailableView.search(text: search.term)
        }
    }
}
