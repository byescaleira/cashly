import CashlyDesignSystem
import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI
import Symbols

extension View {
    public func cashly(
        font: Font = .callout, weight: Font.Weight? = nil, design: Font.Design? = .rounded
    ) -> some View {
        self.font(font).fontWeight(weight).fontDesign(design)
    }
    public func cashly(color: CashlyColor?) -> some View {
        foregroundStyle((color ?? .textSecondary).value)
    }
    public func cashly(tint: CashlyColor) -> some View { self.tint(tint.value) }
    public func cashlyPadding(_ edges: Edge.Set = .all, _ spacing: CashlySpacing = .small)
        -> some View
    { padding(edges, spacing.value) }
    public func cashlyPadding(_ spacing: CashlySpacing) -> some View { padding(spacing.value) }
    public func cashly(background color: CashlyColor) -> some View { background(color.value) }
    public func cashly(clip shape: CashlyShape) -> some View { clipShape(shape) }
    public func cashly(alignment: TextAlignment) -> some View { multilineTextAlignment(alignment) }
    public func cashly(loading: Bool) -> some View { redacted(reason: loading ? .placeholder : []) }
    public func cashlyBackgroundItem() -> some View {
        listRowBackground(Color.secondary.opacity(0.08))
    }
    public func cashlyRounded() -> some View { clipShape(RoundedRectangle(cornerRadius: 32)) }
    @ViewBuilder public func cashly<Content: View>(
        if condition: Bool, _ transform: (Self) -> Content
    )
        -> some View
    {
        if condition { transform(self) } else { self }
    }
    @ViewBuilder public func cashly<Content: View, Value>(
        item: Value?, _ transform: (Self, Value) -> Content
    ) -> some View {
        if let item { transform(self, item) } else { self }
    }
    public func cashly<T: IndefiniteSymbolEffect & SymbolEffect>(
        symbol effect: T,
        options: SymbolEffectOptions = .default, isActive: Bool = true
    ) -> some View {
        symbolEffect(effect, options: options, isActive: isActive)
    }
    public func cashlyDelete(action: @escaping () -> Void) -> some View {
        self.swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                action()
            } label: {
                CashlyLabel("Delete", symbol: "trash.fill")
            }
            .cashly(tint: .error)
        }
    }

    public func cashlyEdit(action: @escaping () -> Void) -> some View {
        self.swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                action()
            } label: {
                CashlyLabel("Edit", symbol: "square.and.pencil")
            }
            .cashly(tint: .info)
        }
    }

    public func cashlyDismiss(isSaved: Bool, selectedUserID: String? = nil) -> some View {
        self.modifier(CashlyDismissModifier(isSaved: isSaved, selectedUserID: selectedUserID))
    }

    public func cashlyIntelligence(
        model: CashlyIntelligence,
        isActive: Bool = true,
        input: Binding<CashlyPredictionInput>,
        result: Binding<CashlyPredictionResult>
    ) -> some View {
        self.modifier(
            CashlyIntelligenceModifier(
                model: model,
                isActive: isActive,
                input: input,
                result: result
            )
        )
    }

}
