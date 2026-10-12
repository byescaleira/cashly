import FeatureCore
import SwiftUI

struct SearchStatusView: View {
    @Environment(SearchModel.self) private var search

    var body: some View {
        if search.term.isEmpty {
            EmptyStateView(
                title: "Buscar no Cashly",
                description: "Procure por descrição, categoria ou tag em todos os períodos."
            ) {
                SearchExample()
            }
        } else if !search.hasResults && !search.isSearching {
            EmptyStateView(
                title: "Nada encontrado para “\(search.term)”",
                description: "Confira a grafia ou tente outra palavra."
            ) {
                SearchExample(term: search.term)
            }
        }
    }
}
