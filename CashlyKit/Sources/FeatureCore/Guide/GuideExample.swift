import CashlyDesignSystem
import SwiftUI

public struct GuideExample<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: 420)
            .background(.sheetCard, in: .rect(cornerRadius: 22))
            .allowsHitTesting(false)
    }
}

public struct ExampleChip: View {
    private let text: String
    private let color: Color

    public init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: .rect(cornerRadius: 8))
    }
}

public struct ExampleRow: View {
    private let symbol: String?
    private let color: Color
    private let title: String
    private let detail: String?
    private let value: String
    private let valueColor: Color

    public init(
        _ title: String, detail: String? = nil, value: String, valueColor: Color = .primary,
        symbol: String? = nil, color: Color = .secondary
    ) {
        self.title = title
        self.detail = detail
        self.value = value
        self.valueColor = valueColor
        self.symbol = symbol
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.2), in: .circle)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.subheadline.weight(.semibold))
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
        }
    }
}

public struct ExampleBar: View {
    private let title: String
    private let detail: String?
    private let ratio: Double
    private let color: Color

    public init(_ title: String, detail: String? = nil, ratio: Double, color: Color) {
        self.title = title
        self.detail = detail
        self.ratio = ratio
        self.color = color
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Text(detail ?? ratio.formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(color)
            }
            .lineLimit(1)
            ProgressView(value: min(ratio, 1)).tint(color)
        }
    }
}

public struct ExampleHeadline: View {
    @Environment(\.appTint) private var appTint
    private let chip: String?
    private let value: String
    private let detail: String?

    public init(chip: String? = nil, value: String, detail: String? = nil) {
        self.chip = chip
        self.value = value
        self.detail = detail
    }

    public var body: some View {
        VStack(spacing: 6) {
            if let chip { ExampleChip(chip.uppercased(), color: appTint) }
            Text(value)
                .font(.system(.title, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let detail {
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

public struct ExampleMonthSummary: View {
    public init() {}

    public var body: some View {
        GuideExample {
            ExampleHeadline(
                chip: Date.now.formatted(.dateTime.month(.wide)),
                value: 3_240.0.formatted(.appCurrency), detail: "disponível no mês")
            Divider()
            ExampleRow(
                "Entradas", value: 6_500.0.formatted(.appCurrency), valueColor: .positive)
            ExampleRow("Saídas", value: 3_260.0.formatted(.appCurrency), valueColor: .negative)
        }
    }
}

public struct ExampleDone: View {
    private let value: String
    private let detail: String

    public init(value: String, detail: String) {
        self.value = value
        self.detail = detail
    }

    public var body: some View {
        GuideExample {
            VStack(spacing: 6) {
                ExampleChip("CONCLUÍDO", color: .positive)
                Text(value)
                    .font(.system(.largeTitle, weight: .black))
                    .foregroundStyle(Color.positive)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }
}

public struct ExampleFile: View {
    private let name: String
    private let detail: String
    private let kind: String

    public init(_ name: String, detail: String, kind: String) {
        self.name = name
        self.detail = detail
        self.kind = kind
    }

    public var body: some View {
        GuideExample {
            HStack(spacing: 12) {
                Text(kind)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.retroTeal)
                    .frame(width: 46, height: 56)
                    .background(Color.retroTeal.opacity(0.2), in: .rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.headline).lineLimit(1)
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
