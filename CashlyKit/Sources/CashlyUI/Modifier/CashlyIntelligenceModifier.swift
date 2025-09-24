//
//  CashlyIntelligenceModifier.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 24/09/25.
//

import SwiftUI
import Combine
import CashlyDomain

struct CashlyIntelligenceModifier: ViewModifier {
    @Environment(\.user) var user
 
    @State var prediction: CashlyPrediction?
    @Binding var input: CashlyPredictionInput
    
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>?
    
    let model: CashlyIntelligence
    let isActive: Bool
    let completion: (CashlyPredictionResult) -> Void
    
    init(
        model: CashlyIntelligence,
        isActive: Bool = true,
        input: Binding<CashlyPredictionInput>,
        publishEvery: TimeInterval? = nil,
        completion: @escaping (CashlyPredictionResult) -> Void
    ) {
        self.model = model
        self.isActive = isActive
        self._input = input
        self.completion = completion
        
        if let publishEvery {
            timer = Timer.publish(
                every: publishEvery,
                on: .main,
                in: .common
            ).autoconnect()
        } else {
            timer = nil
        }
    }
    
    func body(content: Content) -> some View {
        content
            .onAppear { setupPrediction() }
            .cashly(if: timer == nil) {
                $0.onChange(of: input) { predict() }
            }
            .cashly(item: timer) {
                $0.onReceive($1) { _ in predict() }
            }
    }
    
    func setupPrediction() {
        guard let user,
              let model = model.model(for: user)
        else { return }
        Task { @MainActor in
            prediction = await CashlyPrediction(model: model)
        }
    }
    
    func predict() {
        guard let prediction, isActive else { return }
        let input = input
        let completion = completion
        Task { @MainActor in
            switch model {
            case .budgetValue: completion(await prediction.regressionPrediction(from: input))
            case .categoryName: completion(await prediction.textPrediction(from: input))
            case .tagValue: completion(await prediction.regressionPrediction(from: input))
            }
        }
    }
}
