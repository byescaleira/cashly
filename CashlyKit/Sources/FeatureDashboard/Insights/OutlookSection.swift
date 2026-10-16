import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import SwiftUI

struct OutlookSection: View {
    @Environment(InsightsModel.self) private var insights

    var body: some View {
        if let outlook = insights.outlook {
            ProOnly {
                OutlookContent(outlook: outlook)
            }
        }
    }
}

private struct OutlookContent: View {
    let outlook: InsightsModel.Outlook

    var body: some View {
        Section {
            OutlookHero(outlook: outlook)
            OutlookRow(title: "Already spent", value: outlook.spent, marker: .solid)
            OutlookRow(title: "Still to go out", value: outlook.remaining, marker: .faded)
            if let budgeted = outlook.budgeted {
                OutlookRow(title: "Planned", value: budgeted, marker: .line)
            }
            if let daily = outlook.daily, let days = outlook.daysLeft {
                LabeledContent {
                    Text("\(daily.formatted(.appCurrency)) per day")
                        .fontWeight(.semibold)
                        .foregroundStyle(daily > 0 ? Color.positive : .negative)
                } label: {
                    Text("You can spend")
                    Text("over the next \(days) days without going over plan")
                }
            }
        } header: {
            Text("Month Forecast").sectionTitle()
        } footer: {
            Text(
                outlook.isUncertain
                    ? "There are still few days and little history; the forecast improves over time."
                    : "Adds what already went out, scheduled bills and what you usually spend until the end of the month."
            )
        }
    }
}

private struct OutlookHero: View {
    let outlook: InsightsModel.Outlook

    var body: some View {
        let gap = outlook.gap ?? 0
        VStack(spacing: .spaceM) {
            FigureBlock(
                caption: String(appLocalized: "The month should close at"),
                amount: outlook.projected,
                color: gap > 0 ? .negative : .primary)
            if let gap = outlook.gap {
                Chip(
                    gap > 0
                        ? "\(gap.formatted(.appCurrency)) over plan"
                        : "\((-gap).formatted(.appCurrency)) under plan",
                    color: gap > 0 ? .negative : .positive)
            }
            OutlookBar(outlook: outlook)
                .padding(.top, .spaceS)
        }
    }
}

private enum OutlookMarker {
    case solid, faded, line
}

private struct OutlookRow: View {
    @Environment(\.appTint) private var appTint
    let title: LocalizedStringKey
    let value: Double
    let marker: OutlookMarker

    var body: some View {
        LabeledContent {
            Text(value.formatted(.appCurrency)).amountLine()
        } label: {
            Label {
                Text(title)
            } icon: {
                switch marker {
                case .solid: Capsule().fill(appTint).frame(width: 14, height: 8)
                case .faded:
                    Capsule().fill(appTint.opacity(.opacitySoft)).frame(width: 14, height: 8)
                case .line: PlannedDot(size: 12)
                }
            }
        }
    }
}

private struct PlannedDot: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.primary)
            .padding(size * 0.15)
            .background(.groupedRow, in: .circle)
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(.opacityFill), radius: 2, y: 1)
    }
}

private struct OutlookBar: View {
    @Environment(\.appTint) private var appTint
    let outlook: InsightsModel.Outlook

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let spent = width * min(outlook.spent / outlook.scale, 1)
            let projected = width * min(outlook.projected / outlook.scale, 1)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(.opacityFill))
                Capsule().fill(appTint.opacity(.opacitySoft)).frame(width: projected)
                Capsule().fill(appTint).frame(width: max(spent, 14))
                if let budgeted = outlook.budgeted {
                    PlannedDot(size: 20)
                        .offset(x: min(max(width * budgeted / outlook.scale, 10), width - 10) - 10)
                }
            }
        }
        .frame(height: 14)
        .animation(.smooth, value: outlook)
        .accessibilityHidden(true)
    }
}
