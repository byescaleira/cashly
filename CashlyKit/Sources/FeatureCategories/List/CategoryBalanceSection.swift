import CashlyDomain
import FeatureCore
import SwiftUI

struct CategoryBalanceSection: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance

    var body: some View {
        if !finance.categories.isEmpty, !finance.budgets.isEmpty {
            Section {
            } header: {
                VStack(spacing: 16) {
                    Text(session.filter.periodTitle.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.accentColor.opacity(0.2), in: .capsule)
                    Text(finance.budgetsAmount.formatted(.brl))
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(Color.primary)
                        .contentTransition(.numericText(value: finance.budgetsAmount))
                    TopCategories(categories: finance.biggestCategories)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
        }
    }
}

private struct TopCategories: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false
    let categories: [CashlyDomain.Category]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(categories.enumerated(), id: \.offset) { index, category in
                let isEven = index.isMultiple(of: 2)
                let color = Color(hex: category.color)
                Image(systemName: category.icon)
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
                    .accessibilityLabel("\(index + 1). \(category.name)")
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
