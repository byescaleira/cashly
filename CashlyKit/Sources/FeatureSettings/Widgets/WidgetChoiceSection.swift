import CashlyDesignSystem
import CashlyWidgetUI
import SwiftUI

struct WidgetChoiceSection: View {
    @Environment(WidgetsModel.self) private var widgets

    var body: some View {
        Section {
            if !widgets.choices.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140), spacing: .spaceM)],
                    spacing: .spaceM
                ) {
                    ForEach(widgets.choices) { WidgetChoiceCard(choice: $0) }
                }
                .padding(.vertical, .spaceS)
                .sensoryFeedback(.selection, trigger: widgets.selectedChoice.id)
            }
        } header: {
            Text("Budget to Follow").sectionTitle()
        } footer: {
            Text(verbatim: widgets.choiceFooter)
        }
    }
}

private struct WidgetChoiceCard: View {
    @Environment(WidgetsModel.self) private var widgets
    @Environment(\.appTint) private var appTint
    let choice: WidgetChoice

    var body: some View {
        let isSelected = widgets.isSelected(choice)
        let color = choice.color.map { Color(hex: $0) } ?? appTint
        Button {
            widgets.choose(choice)
        } label: {
            VStack(alignment: .leading, spacing: .spaceS) {
                HStack {
                    SymbolBadge(choice.symbol, color: color, size: .badgeS)
                        .symbolEffect(.bounce, value: isSelected)
                    Spacer(minLength: 0)
                    SelectionMark(isSelected: isSelected)
                }
                Text(verbatim: choice.title).font(.rowTitle).lineLimit(1)
                if let ratio = choice.ratio { ChoiceBar(ratio: ratio) }
                Text(verbatim: choice.detail)
                    .font(.rowDetail)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
            }
            .padding(.spaceM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tintedCard(color)
            .overlay {
                RoundedRectangle(cornerRadius: .radiusM)
                    .stroke(isSelected ? appTint : .clear, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: .radiusM))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ChoiceBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFilled = false
    let ratio: Double

    var body: some View {
        UsageBar(ratio: isFilled ? ratio : 0, height: .barHeight / 2, color: .usage(ratio))
            .animation(reduceMotion ? nil : .smooth(duration: 1), value: isFilled)
            .task { isFilled = true }
    }
}
