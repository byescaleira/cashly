import CashlyDesignSystem
import SwiftUI

public struct IconSection: View {
    @Binding private var icon: String
    private let color: Color

    public init(icon: Binding<String>, color: Color) {
        _icon = icon
        self.color = color
    }

    public var body: some View {
        Section {
            NavigationLink {
                IconPickerScreen(icon: $icon, color: color)
            } label: {
                HStack(spacing: 12) {
                    SymbolBadge(symbol: icon, color: color, isSelected: true)
                    Text(SymbolCategory.label(for: icon))
                }
            }
        } header: {
            Text("Ícone").sectionTitle()
        }
    }
}

private struct IconPickerScreen: View {
    @Binding var icon: String
    let color: Color
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let results = SymbolCategory.allCases.map { ($0, $0.symbols(matching: query)) }
            .filter { !$0.1.isEmpty }
        ScrollViewReader { proxy in
            List {
                ForEach(results, id: \.0) { category, symbols in
                    Section(category.name) {
                        SymbolGrid(symbols: symbols, selection: icon, color: color) {
                            icon = $0
                            dismiss()
                        }
                    }
                    .id(category)
                }
            }
            .overlay {
                if results.isEmpty { ContentUnavailableView.search(text: query) }
            }
            #if os(macOS)
                .searchable(text: $query, prompt: "Buscar ícone")
            #else
                .searchable(
                    text: $query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Buscar ícone")
            #endif
            .navigationTitle("Ícone")
            .onAppear {
                if let category = SymbolCategory.containing(icon) {
                    proxy.scrollTo(category, anchor: .center)
                }
            }
        }
    }
}

private struct SymbolGrid: View {
    let symbols: [String]
    let selection: String
    let color: Color
    let select: (String) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 44, maximum: 44), spacing: 12)], spacing: 12
        ) {
            ForEach(symbols, id: \.self) { symbol in
                Button {
                    select(symbol)
                } label: {
                    SymbolBadge(symbol: symbol, color: color, isSelected: symbol == selection)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(SymbolCategory.label(for: symbol))
                .accessibilityAddTraits(symbol == selection ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
    }
}

private struct SymbolBadge: View {
    let symbol: String
    let color: Color
    let isSelected: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(isSelected ? Color.white : Color.secondary)
            .frame(width: 40, height: 40)
            .background(isSelected ? color : .clear, in: .circle)
            .frame(width: 44, height: 44)
            .contentShape(.circle)
    }
}
