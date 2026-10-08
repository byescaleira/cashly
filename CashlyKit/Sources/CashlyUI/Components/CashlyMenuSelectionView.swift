import SwiftUI

struct CashlyMenuSelectionView<Item: Identifiable & Hashable, Content: View, MenuLabel: View>: View
{
    let items: [Item]
    @Binding var selectedItems: Set<Item>
    let content: (Item) -> Content
    let label: MenuLabel
    init(
        items: [Item], selectedItems: Binding<Set<Item>>,
        @ViewBuilder content: @escaping (Item) -> Content, @ViewBuilder label: () -> MenuLabel
    ) {
        self.items = items
        self._selectedItems = selectedItems
        self.content = content
        self.label = label()
    }
    var body: some View {
        Menu {
            ForEach(items) { item in
                let selected = selectedItems.contains { $0.id == item.id }
                Button {
                    selectedItems = Set(selectedItems.filter { $0.id != item.id })
                    if !selected { selectedItems.insert(item) }
                } label: {
                    HStack {
                        if selected { Image(systemName: "checkmark") }
                        content(item)
                    }
                }
            }
            if !selectedItems.isEmpty {
                Divider()
                Button("Clean", systemImage: "eraser.line.dashed") { selectedItems = [] }
            }
        } label: {
            label
        }
    }
}
