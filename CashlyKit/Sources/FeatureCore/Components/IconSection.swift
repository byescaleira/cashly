import CashlyDesignSystem
import SwiftUI

public struct IconSection: View {
    @Binding private var icon: String
    @Binding private var category: SymbolCategory
    private let color: Color

    public init(icon: Binding<String>, category: Binding<SymbolCategory>, color: Color) {
        _icon = icon
        _category = category
        self.color = color
    }

    public var body: some View {
        Section {
            SymbolCategoryChips(selection: $category, color: color)
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 4, trailing: 0))
                .listRowSeparator(.hidden)
            SymbolGrid(symbols: category.symbols, selection: $icon, color: color)
                .listRowSeparator(.hidden)
        } header: {
            HStack(alignment: .firstTextBaseline) {
                Text("Ícone").sectionTitle()
                Spacer()
                Text(category.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
        }
    }
}

private struct SymbolCategoryChips: View {
    @Binding var selection: SymbolCategory
    let color: Color

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SymbolCategory.allCases) { category in
                        CategoryChip(
                            category: category, isSelected: category == selection, color: color
                        ) {
                            selection = category
                        }
                        .id(category)
                    }
                }
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .onAppear { proxy.scrollTo(selection, anchor: .center) }
            .onChange(of: selection) {
                withAnimation { proxy.scrollTo(selection, anchor: .center) }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct CategoryChip: View {
    let category: SymbolCategory
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(category.name, systemImage: category.systemImage)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .foregroundStyle(isSelected ? color : .secondary)
                .background(isSelected ? color.opacity(0.2) : .rowFill, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct SymbolGrid: View {
    let symbols: [String]
    @Binding var selection: String
    let color: Color

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 12)], spacing: 12
        ) {
            ForEach(symbols, id: \.self) { symbol in
                SymbolChoice(symbol: symbol, isSelected: symbol == selection, color: color) {
                    selection = symbol
                }
            }
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct SymbolChoice: View {
    let symbol: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .frame(width: 36, height: 36)
                .background(isSelected ? color : .subtleFill, in: .circle)
                .overlay {
                    if isSelected {
                        Circle().stroke(color, lineWidth: 2).frame(width: 44, height: 44)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(.circle)
                .symbolEffect(.bounce, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol.replacingOccurrences(of: ".", with: " "))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
