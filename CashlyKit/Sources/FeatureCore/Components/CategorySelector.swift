import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct CategorySelector: View {
    private let categories: [CashlyDomain.Category]
    @Binding private var selection: CashlyDomain.Category?

    public init(categories: [CashlyDomain.Category], selection: Binding<CashlyDomain.Category?>) {
        self.categories = categories
        _selection = selection
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(categories) { category in
                        Button {
                            selection = category
                        } label: {
                            CategoryChoice(category: category, isSelected: selection == category)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .id(category)
                        .accessibilityLabel(category.name)
                        .accessibilityAddTraits(selection == category ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 16)
                .onChange(of: selection) {
                    withAnimation(.bouncy) { proxy.scrollTo(selection, anchor: .center) }
                }
            }
            .padding(.horizontal, -16)
        }
    }
}

private struct CategoryChoice: View {
    let category: CashlyDomain.Category
    let isSelected: Bool

    var body: some View {
        let color = isSelected ? Color(hex: category.color) : Color.secondary
        Image(systemName: category.icon)
            .font(.system(size: 20))
            .foregroundStyle(color)
            .frame(width: 45, height: 45)
            .background(color.opacity(0.2), in: .circle)
            .overlay { Circle().stroke(color, lineWidth: 3).frame(width: 50, height: 50) }
            .opacity(isSelected ? 1 : 0.3)
    }
}
