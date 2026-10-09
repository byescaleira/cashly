import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct UnbudgetedCategoriesSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        let categories = finance.categoriesWithoutBudgets
        if !categories.isEmpty, session.filter.isFilteringByDate {
            Section {
                VStack(alignment: .leading) {
                    Text(
                        "Estas categorias ainda não têm orçamento. Toque em uma para definir o valor do mês."
                    )
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(categories) { category in
                                Button {
                                    open(
                                        .addBudget(
                                            id: nil, categoryID: category.id,
                                            date: session.filter.startDate),
                                        in: section)
                                } label: {
                                    CategoryBadge(category: category, ring: 2)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Definir orçamento de \(category.name)")
                                .padding(8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)
                }
                .frame(maxWidth: .infinity)
            } header: {
                Text("Quer mais controle?").sectionTitle()
            }
        }
    }
}
