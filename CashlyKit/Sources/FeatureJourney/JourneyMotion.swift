import CashlyDesignSystem
import SwiftUI

extension View {
    func cascade(_ index: Int) -> some View {
        modifier(Cascade(index: index))
    }
}

private struct Cascade: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false
    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(isShown || reduceMotion ? 1 : 0)
            .scaleEffect(isShown || reduceMotion ? 1 : 0.6)
            .animation(reduceMotion ? nil : .bouncy.delay(Double(index) * 0.04), value: isShown)
            .task { isShown = true }
    }
}

struct FillingBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFilled = false
    let value: Double
    let color: Color
    var marker: Double?

    var body: some View {
        let animation: Animation? = reduceMotion ? nil : .smooth(duration: 1)
        ProgressView(value: isFilled ? min(max(value, 0), 1) : 0)
            .tint(color)
            .animation(animation, value: isFilled)
            .animation(animation, value: value)
            .overlay {
                if let marker {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(Color.primary.opacity(.opacityStrong))
                            .frame(width: .spaceHairline, height: .barHeight)
                            .position(
                                x: proxy.size.width * min(max(marker, 0), 1),
                                y: proxy.size.height / 2)
                    }
                }
            }
            .task { isFilled = true }
            .accessibilityHidden(true)
    }
}

struct InlineLabel: View {
    let title: Text
    let symbol: String

    init(_ title: String, symbol: String) {
        self.title = Text(title)
        self.symbol = symbol
    }

    init(_ key: LocalizedStringKey, symbol: String) {
        title = Text(key)
        self.symbol = symbol
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: .space2XS) {
            Image(systemName: symbol)
            title
        }
    }
}

struct FigureCell: View {
    let caption: LocalizedStringKey
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(spacing: .space2XS) {
            InlineLabel(caption, symbol: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .amountLine()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
