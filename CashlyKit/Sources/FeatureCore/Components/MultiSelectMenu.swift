import SwiftUI

public struct MultiSelectMenu<Item: Identifiable & Hashable, Row: View>: View {
    private let title: LocalizedStringKey
    private let systemImage: String
    private let items: [Item]
    @Binding private var selection: Set<Item>
    private let showsCount: Bool
    private let row: (Item) -> Row

    public init(
        _ title: LocalizedStringKey, systemImage: String, items: [Item],
        selection: Binding<Set<Item>>, showsCount: Bool = true,
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.title = title
        self.systemImage = systemImage
        self.items = items
        _selection = selection
        self.showsCount = showsCount
        self.row = row
    }

    public var body: some View {
        Menu {
            ForEach(items) { item in
                Toggle(isOn: isSelected(item)) { row(item) }
            }
            if !selection.isEmpty {
                Divider()
                Button("Clear", systemImage: "eraser.line.dashed") { selection = [] }
            }
        } label: {
            Label(title, systemImage: systemImage)
            if showsCount, !selection.isEmpty {
                Text("\(selection.count) selected")
            }
        }
    }

    private func isSelected(_ item: Item) -> Binding<Bool> {
        Binding(
            get: { selection.contains { $0.id == item.id } },
            set: { isOn in
                selection = selection.filter { $0.id != item.id }
                if isOn { selection.insert(item) }
            })
    }
}
