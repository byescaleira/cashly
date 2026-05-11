//
//  IntelligenceScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 19/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyData
import CashlyResource
#if DEBUG
import CashlyMock
#endif

public struct IntelligenceScreen: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    
    @State var isTraining: [CashlyIntelligence: Bool] = [:]
    
    public init() {}
    
    public var body: some View {
        CashlyList {
            CashlySystemMonitorView()
            Group {
                modelsSection
                trainButton
            }
            .opacity(state.filter.allTransactions.count < 50 ? 0.5 : 1)
            .disabled(state.filter.allTransactions.count < 50)
        }
        .navigationTitle(CashlyL10n.string("Intelligence"))
        .toolbar {
            ToolbarItem(placement: .navigation) { UserItemView() }
        }
        .onAppear { action(.main(.fetch)) }
        .onChange(of: isTraining) {
            guard isTraining.allSatisfy({ !$0.value }) else { return }
            action(.main(.fetchPredictions))
        }
    }
    
    @ViewBuilder
    var modelsSection: some View {
        if let user = state.user {
            let models = CashlyIntelligence.allCases
            ForEach(models) { model in
                Section {
                    let intelligenceModel = model.model(for: user)
                    CashlyHStack(spacing: .medium) {
                        CashlySymbol(model.icon)
                            .cashly(font: .system(size: 18))
                            .cashly(color: .color(model.color))
                            .frame(width: 40, height: 40)
                            .cashly(background: .color(model.color.opacity(0.2)))
                            .cashly(clip: .circle)
                        
                        CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                            CashlyText(model.name)
                                .cashly(font: .body, weight: .semibold)
                                .cashly(color: .text)
                            
                            if let lastUpdate = intelligenceModel?.updateDate?.date.string(with: .cashly(.transactionSection)) {
                                CashlyText(lastUpdate)
                                    .cashly(font: .callout, weight: .regular)
                                    .cashly(color: .textSecondary)
                            }
                        }
                        .lineLimit(1)
                        
                        CashlySpacer()
                        
                        CashlyZStack {
                            if isTraining[model, default: false] {
                                ProgressView()
                                    .cashly(tint: .textSecondary)
                                    .transition(.scale)
                            } else if intelligenceModel?.createDate != nil {
                                CashlyVStack(alignment: .trailing, spacing: .extraSmall) {
                                    CashlyText(intelligenceModel?.accuracy?.percentage)
                                        .cashly(font: .body, weight: .bold)
                                        .cashly(color: .color(accuracyColor(intelligenceModel?.accuracy)))
                                    
                                    
                                    CashlyText(intelligenceModel?.size)
                                        .cashly(font: .callout)
                                        .cashly(color: .textSecondary)
                                }
                                .transition(.scale)
                            }
                        }
                        .animation(.bouncy, value: isTraining)
                    }
                } header: {
                    if model == .budgetValue {
                        CashlyText(CashlyL10n.string("Models"))
                            .cashly(font: .title3, weight: .semibold)
                            .cashly(color: .text)
                    }
                } footer: {
                    CashlyText(model.summary)
                }
            }
        }
    }
    
    var trainButton: some View {
        Section {} footer: {
            CashlyVStack {
                let disabled = isTraining.contains(where: { $0.value == true })
                CashlyButton {
                    guard let user = state.user else { return }
                    CashlyIntelligence.clean()
                    for model in CashlyIntelligence.allCases {
                        train(model: model, user: user)
                    }
                } label: {
                    CashlyText(CashlyL10n.string("Train Models"))
                        .cashly(font: .headline, weight: .semibold)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.glassProminent)
                .disabled(disabled)
                .cashly(tint: disabled ? .disabled : .primary)
                
                CashlyButton {
                    CashlyIntelligence.clean()
                    action(.main(.fetch))
                } label: {
                    CashlyText(CashlyL10n.string("Clean Models").uppercased())
                        .cashly(font: .caption, weight: .semibold)
                        .cashly(color: .textSecondary)
                }
            }
        }
    }
    
    func train(model: CashlyIntelligence, user: User) {
        guard !isTraining[model, default: false] else { return }
        Task {
            _ = await CashlyIntelligenceService().train(
                model: model,
                user: user,
                transactions: state.filter.allTransactions,
                tags: state.filter.allTags
            )
            isTraining[model, default: false] = false
        }
        isTraining[model, default: false].toggle()
    }
    
    func accuracyColor(_ accuracy: Double?) -> Color {
        guard let accuracy else { return .red }
        switch accuracy {
        case 0.75 ... 0.89: return .orange
        case 0.90 ... 1.0: return .green
        default: return .red
        }
    }
    
    public static var mock: some View {
        IntelligenceScreen()
    }
}

#if DEBUG
#Preview {
    IntelligenceScreen
        .cashlyPreview()
}
#endif
