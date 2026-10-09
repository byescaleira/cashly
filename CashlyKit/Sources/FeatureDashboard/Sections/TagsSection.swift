import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TagsSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(DashboardModel.self) private var dashboard
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        @Bindable var dashboard = dashboard
        if !finance.tags.isEmpty {
            Section {
                if let tag = dashboard.selectedTag {
                    let color = Color(hex: tag.color)
                    Button {
                        open(.addTag(id: tag.id), in: section)
                    } label: {
                        HStack {
                            Text(tag.name.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(color)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(color.opacity(0.2), in: .capsule)
                            Spacer()
                            Text(dashboard.selectedTagAmount.formatted(.appCurrency))
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.primary)
                                .contentTransition(.numericText())
                            Image(systemName: "chevron.forward").foregroundStyle(.disabled)
                        }
                        .animation(.bouncy, value: dashboard.selectedTagAmount)
                    }
                    .tint(Color.primary)
                }
                ExpenseChart(data: dashboard.tagPoints)
                Button {
                    open(.addTag(id: nil), in: section)
                } label: {
                    HStack {
                        Text("Adicionar tag")
                        Spacer()
                        Image(systemName: "chevron.forward").foregroundStyle(.disabled)
                    }
                }
                .tint(Color.primary)
            } header: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags").sectionTitle()
                    SymbolPicker(
                        items: finance.tags, selection: $dashboard.selectedTag, icon: \.icon,
                        color: { Color(hex: $0.color) }, name: \.name, bounces: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
