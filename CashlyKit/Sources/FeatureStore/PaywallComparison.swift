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
                "Recording, editing and the Journey are free forever. Cashly Pro adds insights, intelligence, backups and Claude Code."
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
        case .no:
            Image(systemName: "minus")
                .font(.icon(.s, weight: .semibold))
                .foregroundStyle(.tertiary)
                .accessibilityLabel("Not included")
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
    case record, journey, system, insights, intelligence, backups, claudeCode, exclusives

    enum Value {
        case yes, no
        case text(LocalizedStringKey)
    }

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .record: "Record and edit"
        case .journey: "The Journey: streaks, challenges and achievements"
        case .system: "Widgets, Siri and export"
        case .insights: "Insights and forecasts"
        case .intelligence: "Smart suggestions"
        case .backups: "Automatic backups and imports"
        case .claudeCode: "Claude Code"
        case .exclusives: "Gold icons and avatars"
        }
    }

    var free: Value {
        switch self {
        case .record, .journey, .system: .yes
        case .backups: .text("Export only")
        case .insights, .intelligence, .claudeCode, .exclusives: .no
        }
    }

    var pro: Value { .yes }
}
