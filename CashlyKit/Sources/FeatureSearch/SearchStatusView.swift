import FeatureCore
import SwiftUI

struct SearchStatusView: View {
    @Environment(SearchModel.self) private var search

    var body: some View {
        if search.term.isEmpty {
            EmptyStateView(
                image: .illustrationSearch, title: "Buscar no Cashly",
                description: "Procure por descrição, categoria ou tag em todos os períodos.")
        } else if !search.hasResults && !search.isSearching {
            EmptyStateView(
                image: .illustrationSearch, title: "Nada encontrado para “\(search.term)”",
                description: "Confira a grafia ou tente outra palavra.")
        }
    }
}
