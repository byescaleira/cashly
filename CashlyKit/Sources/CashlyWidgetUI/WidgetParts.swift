import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension Font {
    static let widgetTitle = Font.subheadline.weight(.bold)
    static let widgetAmount = Font.title2.weight(.bold)
    static let widgetSecondary = Font.headline
    static let widgetLabel = Font.system(size: 8, weight: .bold)
    static let widgetValue = Font.system(size: 13, weight: .bold)
    static let widgetRow = Font.system(size: 10)
    static let widgetTag = Font.caption2.weight(.heavy)

    static func widgetAmount(_ size: WidgetSize) -> Font {
        switch size {
        case .large: .largeTitle.weight(.bold)
        case .medium: .title.weight(.bold)
        default: .widgetAmount
        }
    }

    static func widgetSecondary(_ size: WidgetSize) -> Font {
        size == .small ? .widgetSecondary : .title3.weight(.semibold)
    }
}

struct WidgetTitle: View {
    let snapshot: WidgetSnapshot
    let ratio: Double
    var line: WidgetSnapshot.BudgetLine?

    var body: some View {
        HStack(spacing: .spaceXS) {
            if let line {
                Image(systemName: line.icon)
                    .font(.widgetTitle)
                    .foregroundStyle(Color(hex: line.color))
                Text(verbatim: line.categoryName)
            } else {
                Text(verbatim: "Cashly")
            }
            WidgetTag(snapshot.monthLabel, color: .usage(ratio))
        }
        .font(.widgetTitle)
        .fontDesign(.rounded)
        .lineLimit(1)
    }
}

struct WidgetTag: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(verbatim: text)
            .font(.widgetTag)
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, .spaceXS)
            .padding(.vertical, .spaceHairline)
            .background(color.opacity(.opacityTint), in: .rect(cornerRadius: .space2XS))
    }
}

struct WidgetLabel: View {
    let key: LocalizedStringKey

    init(_ key: LocalizedStringKey) {
        self.key = key
    }

    var body: some View {
        Text(key)
            .font(.widgetLabel)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .lineLimit(1)
    }
}

public struct UsageBar: View {
    private let ratio: Double
    private let height: CGFloat
    private let color: Color?

    public init(ratio: Double, height: CGFloat = 6, color: Color? = nil) {
        self.ratio = ratio
        self.height = height
        self.color = color
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(color ?? .usage(ratio))
                    .frame(width: proxy.size.width * min(max(ratio, 0), 1))
            }
        }
        .frame(height: height)
    }
}

struct BudgetCell: View {
    let line: WidgetSnapshot.BudgetLine

    var body: some View {
        HStack(spacing: .spaceXS) {
            SymbolBadge(line.icon, color: Color(hex: line.color), size: 22)
            VStack(spacing: .space2XS) {
                HStack {
                    Text(verbatim: line.categoryName).font(.caption2.weight(.bold)).lineLimit(1)
                    Spacer(minLength: 0)
                    Text(verbatim: line.ratio.percentLabel).font(.caption2).lineLimit(1)
                }
                UsageBar(ratio: line.ratio, height: 4)
            }
        }
    }
}

struct WidgetMessage: View {
    let symbol: String
    let text: Text
    let size: WidgetSize

    var body: some View {
        switch size {
        case .inline:
            Label {
                text
            } icon: {
                Image(systemName: symbol)
            }
        case .circular:
            Image(systemName: symbol).font(.title2)
        case .rectangular:
            VStack(alignment: .leading, spacing: .space2XS) {
                Image(systemName: symbol).font(.headline)
                text.font(.caption).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .small, .medium, .large:
            VStack(spacing: .spaceXS) {
                SymbolBadge(symbol, color: .secondary, size: .badgeM)
                text
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

extension WidgetMessage {
    static func empty(_ size: WidgetSize) -> WidgetMessage {
        WidgetMessage(symbol: "creditcard", text: Text("Open Cashly to see your month"), size: size)
    }

    static func noBudgets(_ size: WidgetSize) -> WidgetMessage {
        WidgetMessage(symbol: "square.grid.2x2", text: Text("No budgets this month"), size: size)
    }
}
