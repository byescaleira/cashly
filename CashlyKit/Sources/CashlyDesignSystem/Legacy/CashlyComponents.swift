import SwiftUI

public struct CashlyText: View {
    let value: String
    public init(_ value: String?) { self.value = value ?? "" }
    public var body: some View { Text(LocalizedStringKey(value)) }
}
public struct CashlySymbol: View {
    let name: String
    let mode: SymbolRenderingMode?
    public init(_ name: String, mode: SymbolRenderingMode? = nil) {
        self.name = name
        self.mode = mode
    }
    public var body: some View { Image(systemName: name).symbolRenderingMode(mode) }
}
public struct CashlyLabel: View {
    let title: String
    let symbol: String
    public init(_ title: String, symbol: String) {
        self.title = title
        self.symbol = symbol
    }
    public var body: some View { Label(LocalizedStringKey(title), systemImage: symbol) }
}
public struct CashlyHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CashlySpacing
    let content: Content
    public init(
        alignment: VerticalAlignment = .center, spacing: CashlySpacing = .small,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    public var body: some View { HStack(alignment: alignment, spacing: spacing.value) { content } }
}
public struct CashlyVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CashlySpacing
    let content: Content
    public init(
        alignment: HorizontalAlignment = .center, spacing: CashlySpacing = .small,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    public var body: some View { VStack(alignment: alignment, spacing: spacing.value) { content } }
}
public struct CashlyHorizontalList<Content: View>: View {
    let content: (ScrollViewProxy) -> Content
    public init(@ViewBuilder content: @escaping (ScrollViewProxy) -> Content) {
        self.content = content
    }
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) { content(proxy) }
        }
    }
}
public struct CashlyCurrencyTextField: View {
    @Binding var amount: Double
    public init(amount: Binding<Double>) { _amount = amount }
    public var body: some View {
        TextField(
            "Amount", value: $amount,
            format: .currency(code: Locale.current.currency?.identifier ?? "BRL")
        )
        #if os(iOS)
            .keyboardType(.decimalPad)
        #endif
    }
}
