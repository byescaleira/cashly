//
//  CategoryVariationView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyPresentation
#if DEBUG
import CashlyMock
#endif

struct CategoryVariationView: CashlyView {
    @Environment(\.mainState) var state
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
                .onChange(of: variation.variationColor) { restartAnimation(value: variation) }
                .task { restartAnimation(value: variation, needRestart: false) }
        }
    }
    
    func restartAnimation(value: Double, needRestart: Bool = true) {
        if needRestart {
            variation = .zero
        }
        Task {
            try await Task.sleep(for: .seconds(0.5))
            variation = value
        }
    }
    
    var variationView: some View {
        CashlyZStack {
            if variation != .zero {
                CashlyHStack(spacing: .extraSmall) {
                    ForEach(1 ... 4, id: \.self) { index in
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
    
    #if DEBUG
    static var mock: some View {
        CategoryVariationView(category: .mock)
    }
    #endif
}

#if DEBUG
#Preview {
    CategoryVariationView
        .cashlyPreview()
}
#endif
