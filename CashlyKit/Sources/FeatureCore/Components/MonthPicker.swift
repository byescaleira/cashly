import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct MonthPicker: View {
    @Binding private var selection: YearMonth
    @State private var year: Int
    @Environment(\.appTint) private var appTint

    public init(selection: Binding<YearMonth>) {
        _selection = selection
        _year = State(initialValue: selection.wrappedValue.year)
    }

    public var body: some View {
        VStack(spacing: .spaceL) {
            HStack {
                Button("Previous Year", systemImage: "chevron.left") { year -= 1 }
                Spacer()
                Text(String(year))
                    .font(.amountRow)
                    .contentTransition(.numericText(value: Double(year)))
                Spacer()
                Button("Next Year", systemImage: "chevron.right") { year += 1 }
            }
            .labelStyle(.iconOnly)
            .font(.buttonLabel)
            .buttonStyle(.borderless)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: .spaceS), count: 4),
                spacing: .spaceS
            ) {
                ForEach(1...12, id: \.self) { month in
                    MonthCell(
                        title: Self.symbols[month - 1],
                        isSelected: selection == YearMonth(year: year, month: month),
                        isCurrent: YearMonth(.now) == YearMonth(year: year, month: month),
                        tint: appTint
                    ) {
                        if let value = YearMonth(year: year, month: month) { selection = value }
                    }
                }
            }
        }
        .padding(.vertical, .spaceS)
        .animation(.snappy, value: year)
        .sensoryFeedback(.selection, trigger: selection)
        .onChange(of: selection) { _, value in year = value.year }
    }

    private static let symbols: [String] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .app
        return calendar.shortStandaloneMonthSymbols.map {
            $0.replacingOccurrences(of: ".", with: "").capitalized
        }
    }()
}

private struct MonthCell: View {
    let title: String
    let isSelected: Bool
    let isCurrent: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : isCurrent ? tint : Color.primary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(isSelected ? tint : Color.secondary.opacity(.opacityFill), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
