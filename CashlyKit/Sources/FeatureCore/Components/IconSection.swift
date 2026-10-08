import CashlyDesignSystem
import SwiftUI

public struct IconSection: View {
    public enum Layout {
        case strip, grid
    }

    @Binding private var icon: String
    @Binding private var category: SymbolCategory
    private let color: Color
    private let layout: Layout

    public init(
        icon: Binding<String>, category: Binding<SymbolCategory>, color: Color,
        layout: Layout = .strip
    ) {
        _icon = icon
        _category = category
        self.color = color
        self.layout = layout
    }

    public var body: some View {
        Section {
            HStack {
                Text("Categoria")
                Spacer()
                Menu {
                    Picker(selection: $category) {
                        ForEach(SymbolCategory.allCases, id: \.self) { Text($0.name).tag($0) }
                    } label: {
                        Text(category.name)
                    }
                } label: {
                    HStack {
                        Text(category.name).font(.body.weight(.semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.semibold))
                    }
                }
                .tint(color)
            }
        } header: {
            Text("Ícone").sectionTitle()
        } footer: {
            if layout == .strip {
                IconStrip(symbols: category.symbols, selection: $icon, color: color)
            }
        }
        if layout == .grid {
            Section {
                IconGrid(symbols: category.symbols, selection: $icon, color: color)
            }
        }
    }
}

private struct IconStrip: View {
    let symbols: [String]
    @Binding var selection: String
    let color: Color

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(symbols, id: \.self) { symbol in
                        IconChoice(symbol: symbol, isSelected: symbol == selection, color: color) {
                            selection = symbol
                        }
                        .padding(8)
                    }
                }
                .task(id: selection) {
                    try? await Task.sleep(for: .milliseconds(200))
                    guard !Task.isCancelled else { return }
                    withAnimation(.bouncy.speed(0.5)) {
                        proxy.scrollTo(selection, anchor: .center)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.horizontal, -40)
        }
    }
}

private struct IconGrid: View {
    let symbols: [String]
    @Binding var selection: String
    let color: Color

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 45, maximum: 45))], alignment: .leading,
            spacing: 16
        ) {
            ForEach(symbols, id: \.self) { symbol in
                IconChoice(symbol: symbol, isSelected: symbol == selection, color: color) {
                    selection = symbol
                }
                .padding(8)
            }
        }
    }
}
