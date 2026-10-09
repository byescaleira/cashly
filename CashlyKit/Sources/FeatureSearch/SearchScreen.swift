import FeatureCore
import SwiftUI

public struct SearchScreen: View {
    @Environment(SearchModel.self) private var search

    public init() {}

    public var body: some View {
        @Bindable var search = search
        List {
            TransactionResultsSection()
            CategoryResultsSection()
            TagResultsSection()
        }
        .overlay { SearchStatusView() }
        .navigationTitle("Buscar")
        .searchable(text: $search.text, prompt: "Transações, categorias e tags")
        .toolbar { ToolbarItem(placement: .leading) { UserMenu() } }
        .task(id: search.searchKey) { await search.search() }
        .errorAlert($search.error)
    }
}
