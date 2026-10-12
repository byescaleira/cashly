import CashlyDesignSystem
import SwiftUI

public struct PeriodSummaryHeader: View {
    @Environment(\.appTint) private var appTint

    public struct Item: Identifiable {
        public let id: String
        public let name: String
        public let icon: String
        public let color: Color

        public init(id: String, name: String, icon: String, color: Color) {
            self.id = id
            self.name = name
            self.icon = icon
            self.color = color
        }
    }

    @Environment(SessionModel.self) private var session
    private let amount: Double
    private let items: [Item]
    private let badge: (title: String, color: Color)?

    public init(amount: Double, items: [Item], badge: (title: String, color: Color)? = nil) {
        self.amount = amount
        self.items = items
        self.badge = badge
    }

    public var body: some View {
        Section {
        } header: {
            VStack(spacing: .spaceL) {
                let badge = badge ?? (session.filter.periodTitle, appTint)
                Chip(badge.title.uppercased(), color: badge.color, shape: .capsule)
                Text(amount.formatted(.appCurrency))
                    .font(.amountHero)
                    .foregroundStyle(Color.primary)
                    .contentTransition(.numericText(value: amount))
                    .amountLine()
                RankedSymbols(items: items)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, .spaceL)
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
                let color = item.color
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 45, height: 45)
                    .overlay(alignment: isEven ? .topLeading : .bottomLeading) {
                        Text(String(index + 1))
                            .font(.chipLabel)
                            .foregroundStyle(color)
                            .padding(.spaceS)
                            .clearSurface(in: .circle)
                            .padding(-.spaceS)
                            .dynamicTypeSize(...DynamicTypeSize.large)
                    }
                    .background(color.opacity(.opacityTint), in: .circle)
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
