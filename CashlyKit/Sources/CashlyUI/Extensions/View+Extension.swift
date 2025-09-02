//
//  View+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import SwiftUI
import RyzeUI

public extension View {
    func cashly(
        font: Font,
        weight: Font.Weight? = nil,
        design: Font.Design? = .rounded
    ) -> some View {
        self.ryze(
            font: font,
            weight: weight,
            design: design
        )
    }
    
    func cashly(color: CashlyColor?) -> some View {
        self.ryze(color: color ?? .textSecondary)
    }
    
    func cashly(tint: CashlyColor) -> some View {
        self.ryze(tint: tint)
    }
    
    func cashlyPadding(
        _ edges: Edge.Set = .all,
        _ spacing: CashlySpacing = .small,
    ) -> some View {
        self.ryzePadding(
            edges,
            spacing
        )
    }
    
    func cashlyPadding(_ spacing: CashlySpacing = .small) -> some View {
        self.ryzePadding(spacing)
    }
    
    func cashly(glass: Glass, in shape: CashlyShape) -> some View {
        self.glassEffect(glass, in: shape)
    }
    
    func cashly(background color: CashlyColor) -> some View {
        self.ryze(background: color)
    }
    
    func cashly(clip shape: CashlyShape) -> some View {
        self.ryze(clip: shape)
    }
    
    func cashly(alignment: TextAlignment) -> some View {
        self.ryze(alignment: alignment)
    }
    
    func cashly(loading: Bool) -> some View {
        self.ryze(if: loading) { $0.redacted(reason: .placeholder) }
    }
    
    func cashlyBackgroundItem() -> some View {
        self.ryzeBackgroundRow()
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
    
    func cashly<Content: View>(if condition: Bool, _ transform: (Self) -> Content) -> some View {
        self.ryze(if: condition, transform: transform)
    }
    
    func cashlyConfetti(for seconds: Int = 3) -> some View {
        self.ryzeConfetti(seconds: seconds)
    }
    
    func cashly<T: IndefiniteSymbolEffect & SymbolEffect>(
        symbol effect: T,
        options: SymbolEffectOptions = .default,
        isActive: Bool = true
    ) -> some View {
        self.ryzeSymbol(
            effect: effect,
            options: options,
            isActive: isActive
        )
    }
}
