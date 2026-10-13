import CashlyDesignSystem
import SwiftUI

struct PaywallComparison: View {
    private static let column: CGFloat = 72

    var body: some View {
        VStack(spacing: .spaceM) {
            VStack(spacing: 0) {
                header
                ForEach(PaywallFeature.allCases) { feature in
                    Divider()
                    row(feature)
                }
            }
            .padding(.horizontal, .spaceM)
            .padding(.vertical, .spaceS)
            .background(alignment: .trailing) { proColumn }
            .background(.sheetCard, in: .rect(cornerRadius: .radiusL))
            Text(
                "Without Cashly Pro your data stays visible and exportable, but recording and editing are locked."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }

    private var header: some View {
        HStack(spacing: .spaceS) {
            Spacer(minLength: 0)
            Text("Free")
                .font(.chipLabel)
                .foregroundStyle(.secondary)
                .frame(width: Self.column)
            Text("Pro")
                .font(.chipLabel)
                .foregroundStyle(Color.retroMustard)
                .frame(width: Self.column)
        }
        .textCase(.uppercase)
        .padding(.vertical, .spaceS)
    }

    private var proColumn: some View {
        RoundedRectangle(cornerRadius: .radiusM)
            .fill(Color.retroMustard.opacity(.opacityFill))
            .frame(width: Self.column + .spaceS)
            .padding(.trailing, .spaceS)
            .padding(.vertical, .spaceS)
    }

    private func row(_ feature: PaywallFeature) -> some View {
        HStack(spacing: .spaceS) {
            Text(feature.title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            PaywallCell(value: feature.free).frame(width: Self.column)
            PaywallCell(value: feature.pro).frame(width: Self.column)
        }
        .padding(.vertical, .spaceM)
        .accessibilityElement(children: .combine)
    }
}

private struct PaywallCell: View {
    let value: PaywallFeature.Value

    var body: some View {
        switch value {
        case .yes:
            Image(systemName: "checkmark.circle.fill")
                .font(.icon(.m, weight: .semibold))
                .foregroundStyle(Color.retroOlive)
                .accessibilityLabel("Included")
        case .text(let key):
            Text(key)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
        }
    }
}

enum PaywallFeature: CaseIterable, Identifiable {
    case record, budgets, insights, journey, backups, system

    enum Value {
        case yes
        case text(LocalizedStringKey)
    }

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .record: "Record and edit"
        case .budgets: "Budgets and goals"
        case .insights: "Insights and forecasts"
        case .journey: "The Journey: streaks, challenges, shop"
        case .backups: "Backups, imports and Claude Code"
        case .system: "Widgets, Siri and export"
        }
    }

    var free: Value {
        switch self {
        case .record: .text("Trial only")
        case .budgets, .insights, .backups: .text("Read-only")
        case .journey: .text("Paused")
        case .system: .yes
        }
    }

    var pro: Value { .yes }
}
