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
        VStack(spacing: 16) {
            HStack {
                Button("Ano anterior", systemImage: "chevron.left") { year -= 1 }
                Spacer()
                Text(String(year))
                    .font(.title3.weight(.bold))
                    .contentTransition(.numericText(value: Double(year)))
                Spacer()
                Button("Próximo ano", systemImage: "chevron.right") { year += 1 }
            }
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .buttonStyle(.borderless)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8
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
        .padding(.vertical, 8)
        .animation(.snappy, value: year)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private static let symbols: [String] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "pt_BR")
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
                .background(isSelected ? tint : Color.secondary.opacity(0.1), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
