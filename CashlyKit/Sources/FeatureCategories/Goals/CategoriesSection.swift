import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct CategoriesSection: View {
    @Environment(GoalsModel.self) private var goals
    @Environment(FinanceModel.self) private var finance
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        Section {
            ForEach(goals.categories) { category in
                Button {
                    open(.addCategory(id: category.id), in: section)
                } label: {
                    HStack(spacing: .spaceM) {
                        SymbolBadge(category.icon, color: Color(hex: category.color))
                        VStack(alignment: .leading, spacing: .spaceHairline) {
                            Text(category.name).font(.rowTitle)
                            Text(goals.caption(for: category))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(finance.expensesAmount(for: category).formatted(.appCurrency))
                            .font(.callout.weight(.semibold))
                            .amountLine()
                    }
                    .contentShape(.rect)
                }
                .tint(Color.primary)
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        goals.deletion = .category(category)
                    }
                    Button("Edit", systemImage: "square.and.pencil") {
                        open(.addCategory(id: category.id), in: section)
                    }
                }
                .contextMenu {
                    Button("Edit", systemImage: "square.and.pencil") {
                        open(.addCategory(id: category.id), in: section)
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        goals.deletion = .category(category)
                    }
                }
            }
        } header: {
            Text("Categories").sectionTitle()
        } footer: {
            Text("Tap to edit and swipe to delete. The amount is the spending in the period.")
        }
    }
}
