//
//  View+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import SwiftUI
import CashlyResource
import CashlyDomain
import CashlyDesignSystem

public extension View {
    func cashly(
        font: Font = .callout,
        weight: Font.Weight? = nil,
        design: Font.Design? = .rounded
    ) -> some View {
        self.font(font)
            .fontWeight(weight)
            .fontDesign(design)
    }
    
    func cashly(color: CashlyColor?) -> some View {
        self.foregroundStyle((color ?? .textSecondary).resolved)
    }

    func cashly(tint: CashlyColor) -> some View {
        self.tint(tint.resolved)
    }
    
    func cashlyPadding(
        _ edges: Edge.Set = .all,
        _ spacing: CashlySpacing = .small,
    ) -> some View {
        self.padding(edges, spacing.rawValue)
    }

    func cashlyPadding(_ spacing: CashlySpacing = .small) -> some View {
        self.padding(spacing.rawValue)
    }
    
    func cashly(glass: Glass, in shape: CashlyShape) -> some View {
        self.glassEffect(glass, in: shape)
    }
    
    func cashly(background color: CashlyColor) -> some View {
        self.background(color.resolved)
    }
    
    func cashly(clip shape: CashlyShape) -> some View {
        self.clipShape(shape)
    }

    func cashly(alignment: TextAlignment) -> some View {
        self.multilineTextAlignment(alignment)
    }
    
    func cashly(loading: Bool) -> some View {
        self.redacted(reason: loading ? .placeholder : [])
            .environment(\.isLoading, loading)
    }

    func cashlyBackgroundItem() -> some View {
        self.modifier(CashlyBackgroundRowModifier())
    }
    
    func cashlyRounded() -> some View {
        self.cashly(clip: .rounded(radius: 32))
    }
    
    func cashly<V>(environment: WritableKeyPath<EnvironmentValues, V>, _ value: V) -> some View {
        self.environment(environment, value)
    }
    
    func cashly<T>(object: T) -> some View where T : ObservableObject {
        self.environmentObject(object)
    }
    
    func cashly(colorScheme: ColorScheme?) -> some View {
        self.preferredColorScheme(colorScheme)
    }
    
    @ViewBuilder
    func cashly<Content: View>(if condition: Bool, _ transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }

    @ViewBuilder
    func cashly<Content: View, Value>(item: Value?, _ transform: (Self, Value) -> Content) -> some View {
        if let item { transform(self, item) } else { self }
    }

    func cashlyConfetti(for seconds: Int = 3, isActive: Bool = true) -> some View {
        self.cashlyConfetti(amount: 30, seconds: seconds, isActive: isActive)
    }

    func cashly<T: IndefiniteSymbolEffect & SymbolEffect>(
        symbol effect: T,
        options: SymbolEffectOptions = .default,
        isActive: Bool = true
    ) -> some View {
        self.symbolEffect(effect, options: options, isActive: isActive)
    }
    
    func cashlyDelete(action: @escaping () -> Void) -> some View {
        self.swipeActions(edge: .trailing, allowsFullSwipe: true) {
            CashlyButton(role: .destructive) {
                action()
            } label: {
                CashlyLabel(CashlyL10n.string("Delete"), symbol: "trash.fill")
            }
            .cashly(tint: .error)
        }
    }
    
    func cashlyEdit(action: @escaping () -> Void) -> some View {
        self.swipeActions(edge: .trailing, allowsFullSwipe: false) {
            CashlyButton {
                action()
            } label: {
                CashlyLabel(CashlyL10n.string("Edit"), symbol: "square.and.pencil")
            }
            .cashly(tint: .info)
        }
    }
    
    func cashlyDismiss(isSaved: Bool) -> some View {
        self.modifier(CashlyDismissModifier(isSaved: isSaved))
    }
    
    func cashlyIntelligence(
        model: CashlyIntelligence,
        isActive: Bool = true,
        input: Binding<CashlyPredictionInput>,
        publishEvery: TimeInterval? = nil,
        result: Binding<CashlyPredictionResult>
    ) -> some View {
        self.modifier(
            CashlyIntelligenceModifier(
                model: model,
                isActive: isActive,
                input: input,
                publishEvery: publishEvery,
                result: result
            )
        )
    }
    
}
