import CashlyDesignSystem
import SwiftUI

public struct PeriodSummaryHeader: View {
    public struct Item: Identifiable {
        public let id: String
        public let name: String
        public let icon: String
        public let color: String

        public init(id: String, name: String, icon: String, color: String) {
            self.id = id
            self.name = name
            self.icon = icon
            self.color = color
        }
    }

    @Environment(SessionModel.self) private var session
    private let amount: Double
    private let items: [Item]

    public init(amount: Double, items: [Item]) {
        self.amount = amount
        self.items = items
    }

    public var body: some View {
        Section {
        } header: {
            VStack(spacing: 16) {
                Text(session.filter.periodTitle.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.accentColor.opacity(0.2), in: .capsule)
                Text(amount.formatted(.brl))
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText(value: amount))
                RankedSymbols(items: items)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
        }
    }
}

private struct RankedSymbols: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false
    let items: [PeriodSummaryHeader.Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.enumerated(), id: \.offset) { index, item in
                let isEven = index.isMultiple(of: 2)
                let color = Color(hex: item.color)
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 45, height: 45)
                    .overlay(alignment: isEven ? .topLeading : .bottomLeading) {
                        Text(String(index + 1))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(color)
                            .padding(8)
                            .background(Color(white: 0.95), in: .circle)
                            .padding(-8)
                    }
                    .background(color.opacity(0.2), in: .circle)
                    .offset(y: isFloating == isEven ? -3 : 3)
                    .animation(
                        .linear.speed(0.5).repeatCount(isFloating ? .max : 0, autoreverses: true),
                        value: isFloating
                    )
                    .accessibilityLabel("\(index + 1). \(item.name)")
            }
        }
        .minimumScaleFactor(0.3)
        .task(id: reduceMotion) {
            isFloating = false
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .seconds(1))
            isFloating = !Task.isCancelled
        }
    }
}
