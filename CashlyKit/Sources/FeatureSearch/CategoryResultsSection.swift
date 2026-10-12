import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct CategoryResultsSection: View {
    @Environment(SearchModel.self) private var search
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if !search.categories.isEmpty {
            Section("Categorias") {
                ForEach(search.categories) { category in
                    Button {
                        open(.addCategory(id: category.id), in: section)
                    } label: {
                        Label {
                            Text(category.name.capitalized).foregroundStyle(Color.primary)
                        } icon: {
                            Image(systemName: category.icon).foregroundStyle(
                                Color(hex: category.color))
                        }
                    }
                }
            }
        }
    }
}
