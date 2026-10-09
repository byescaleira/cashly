import FeatureCore
import SwiftUI

public struct CategoryDetailScreen: View {
    @Environment(FinanceModel.self) private var finance
    private let categoryID: String

    public init(categoryID: String) {
        self.categoryID = categoryID
    }

    public var body: some View {
        let category = finance.category(id: categoryID)
        List {
            CategoryDetailHeader(category: category)
            CategoryBudgetsSection(category: category)
        }
        .fontDesign(.rounded)
        .navigationTitle(category.name.capitalized)
        .refreshable { await finance.load() }
    }
}
