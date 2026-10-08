import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import Foundation
import SwiftUI

struct CategoryVariationView: View {
    @Environment(MainViewModel.self) var state
    @State var variation: Double = .zero

    var category: CashlyDomain.Category?
    var amount: Double

    init(category: CashlyDomain.Category? = nil, amount: Double = .zero) {
        self.category = category
        self.amount = amount
    }

    @ViewBuilder
    var body: some View {
        if let category {
            let variation = state.categoryVariation(
                category: category,
                amount: amount
            )
            variationView
                .task(id: variation) {
                    self.variation = .zero
                    do {
                        try await Task.sleep(for: .milliseconds(500))
                        try Task.checkCancellation()
                        self.variation = variation
                    } catch {}
                }
        }
    }

    var variationView: some View {
        ZStack {
            if variation != .zero {
                CashlyHStack(spacing: .extraSmall) {
                    ForEach(1...4, id: \.self) { index in
                        Circle()
                            .fill(getColor(index: index, variation: variation))
                            .frame(width: 10, height: 10)
                    }
                }
                .transition(
                    .move(edge: .bottom)
                )
            }
        }
        .animation(.bouncy.speed(1.5), value: variation)
    }

    func getColor(index: Int, variation: Double) -> Color {
        let variationColor = variation.variationColor
        switch (index, variationColor) {
        case (1, .green), (1, .yellow), (1, .orange), (1, .red): return .green
        case (2, .yellow), (2, .orange), (2, .red): return .yellow
        case (3, .orange), (3, .red): return .orange
        case (4, .red): return .red
        default: return .secondary.opacity(0.2)
        }
    }

}
