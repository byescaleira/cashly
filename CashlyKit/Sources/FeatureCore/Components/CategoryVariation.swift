import CashlyDomain
import SwiftUI

public struct CategoryVariation: View {
    @Environment(FinanceModel.self) private var finance
    @State private var shown: BudgetUsage.Stage?
    private let category: CashlyDomain.Category
    private let amount: Double

    public init(category: CashlyDomain.Category, amount: Double = .zero) {
        self.category = category
        self.amount = amount
    }

    public var body: some View {
        let usage = finance.categoryUsage(category: category, adding: amount)
        ZStack {
            if let shown, usage.ratio != .zero {
                HStack(spacing: 4) {
                    ForEach(1...4, id: \.self) { index in
                        Circle().fill(shown.dotColor(at: index)).frame(width: 10, height: 10)
                    }
                }
                .transition(.move(edge: .bottom))
                .accessibilityElement()
                .accessibilityLabel(shown.title)
            }
        }
        .animation(.bouncy.speed(1.5), value: shown)
        .task(id: usage.ratio) {
            shown = nil
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            shown = usage.stage
        }
    }
}
