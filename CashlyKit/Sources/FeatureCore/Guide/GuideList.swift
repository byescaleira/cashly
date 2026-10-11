import CashlyDesignSystem
import SwiftUI

public struct GuideFeature: View {
    @Environment(\.appTint) private var appTint
    private let symbol: String
    private let title: String
    private let detail: String?
    private let color: Color?

    public init(_ symbol: String, title: String, detail: String? = nil, color: Color? = nil) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
        self.color = color
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color ?? appTint)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                if let detail {
                    Text(detail).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

public struct GuideFeatureList<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) { content }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

public struct GuideValue: View {
    private let label: String
    private let value: String
    private let color: Color

    public init(_ label: String, value: String, color: Color = .primary) {
        self.label = label
        self.value = value
        self.color = color
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value).fontWeight(.semibold).foregroundStyle(color).multilineTextAlignment(
                .trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
    }
}

public struct GuideValueList: View {
    private let rows: [GuideValue]

    public init(_ rows: [GuideValue]) {
        self.rows = rows
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                rows[index]
                if index < rows.count - 1 { Divider().padding(.leading, 16) }
            }
        }
        .background(.groupedRow, in: .rect(cornerRadius: 18))
    }
}
