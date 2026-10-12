import CashlyDesignSystem
import SwiftUI

public struct SymbolPicker<Item: Identifiable & Hashable>: View {
    private let items: [Item]
    @Binding private var selection: Item?
    private let icon: (Item) -> String
    private let color: (Item) -> Color
    private let name: (Item) -> String
    private let bounces: Bool

    public init(
        items: [Item], selection: Binding<Item?>, icon: @escaping (Item) -> String,
        color: @escaping (Item) -> Color, name: @escaping (Item) -> String, bounces: Bool = false
    ) {
        self.items = items
        _selection = selection
        self.icon = icon
        self.color = color
        self.name = name
        self.bounces = bounces
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(items) { item in
                        let isSelected = selection == item
                        Button {
                            selection = item
                        } label: {
                            SymbolChoice(
                                icon: icon(item), color: isSelected ? color(item) : .secondary,
                                isSelected: isSelected, bounces: bounces)
                        }
                        .buttonStyle(.plain)
                        .padding(.spaceS)
                        .id(item)
                        .accessibilityLabel(name(item))
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, .spaceL)
                .task(id: selection) {
                    try? await Task.sleep(for: .milliseconds(200))
                    guard !Task.isCancelled else { return }
                    withAnimation(.bouncy.speed(0.5)) { proxy.scrollTo(selection, anchor: .center) }
                }
            }
            .padding(.horizontal, -.spaceL)
        }
    }
}

private struct SymbolChoice: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    let bounces: Bool

    var body: some View {
        Image(systemName: icon)
            .font(.icon(.m))
            .foregroundStyle(color)
            .frame(width: 45, height: 45)
            .background(color.opacity(.opacityTint), in: .circle)
            .overlay { Circle().stroke(color, lineWidth: 3).frame(width: 50, height: 50) }
            .opacity(isSelected ? 1 : 0.3)
            .symbolEffect(
                .bounce.byLayer, options: .repeat(.continuous).speed(0.1),
                isActive: bounces && isSelected)
    }
}
