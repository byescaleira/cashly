import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct TagsSection: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(ReportsModel.self) private var reports

    var body: some View {
        if !finance.tags.isEmpty {
            ProCurtainSection(.tags) {
                TagsContent()
            } preview: {
                ExpenseChart(data: reports.tagPoints)
            }
        }
    }
}

private struct TagsContent: View {
    @Environment(FinanceModel.self) private var finance
    @Environment(ReportsModel.self) private var reports
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        @Bindable var reports = reports
        Section {
            if let tag = reports.selectedTag {
                let color = Color(hex: tag.color)
                Button {
                    open(.addTag(id: tag.id), in: section)
                } label: {
                    HStack {
                        AdaptiveStack(spacing: .spaceS) {
                            Text(tag.name.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(color)
                                .padding(.vertical, .spaceS)
                                .padding(.horizontal, .spaceM)
                                .background(color.opacity(.opacityTint), in: .capsule)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(reports.selectedTagAmount.formatted(.appCurrency))
                                .font(.amountRow)
                                .foregroundStyle(Color.primary)
                                .contentTransition(.numericText())
                                .amountLine()
                        }
                        Image(systemName: "chevron.forward").foregroundStyle(.disabled)
                    }
                    .animation(.bouncy, value: reports.selectedTagAmount)
                }
                .tint(Color.primary)
            }
            ExpenseChart(data: reports.tagPoints)
            Button {
                open(.addTag(id: nil), in: section)
            } label: {
                HStack {
                    Text("Add Tag")
                    Spacer()
                    Image(systemName: "chevron.forward").foregroundStyle(.disabled)
                }
            }
            .tint(Color.primary)
        } header: {
            VStack(alignment: .leading, spacing: .spaceS) {
                Text("Tags").sectionTitle()
                SymbolPicker(
                    items: finance.tags, selection: $reports.selectedTag, icon: \.icon,
                    color: { Color(hex: $0.color) }, name: \.name, bounces: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
