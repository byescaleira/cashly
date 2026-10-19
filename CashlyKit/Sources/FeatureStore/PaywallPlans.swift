import CashlyDesignSystem
import CashlyDomain
import SwiftUI

struct PaywallTimeline: View {
    let days: Int

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceL) {
            PaywallStep(
                symbol: "lock.open.fill", color: .retroOlive, title: "Today",
                detail: "Full access to everything in Cashly Pro.")
            PaywallStep(
                symbol: "bell.fill", color: .retroMustard, title: "Day \(days - 2)",
                detail: "A reminder before the charge.")
            PaywallStep(
                symbol: "creditcard.fill", color: .retroDenim, title: "Day \(days)",
                detail: "Your subscription starts. Cancel anytime before.")
        }
        .background(alignment: .leading) {
            Rectangle()
                .fill(Color.secondary.opacity(.opacitySoft))
                .frame(width: .spaceHairline)
                .padding(.vertical, .badgeM / 2)
                .padding(.leading, .badgeM / 2 - .spaceHairline / 2)
        }
        .padding(.spaceL)
        .background(.sheetCard, in: .rect(cornerRadius: .radiusL))
    }
}

private struct PaywallStep: View {
    let symbol: String
    let color: Color
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: .spaceM) {
            SymbolBadge(symbol, color: color, size: .badgeM, style: .filled)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(title).font(.rowTitle)
                Text(detail).font(.rowDetail).foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct PaywallPlans: View {
    @Environment(StoreModel.self) private var store

    var body: some View {
        @Bindable var store = store
        VStack(spacing: .spaceS) {
            ForEach(store.plans) { plan in
                PaywallPlanCard(
                    plan: plan, isSelected: store.selectedPlan == plan.item,
                    trialDays: store.trialDays(for: plan.item)
                ) {
                    store.selectedPlan = plan.item
                }
            }
        }
        .animation(.smooth, value: store.selectedPlan)
    }
}

private struct PaywallPlanCard: View {
    @Environment(\.appTint) private var appTint
    let plan: PaywallPlan
    let isSelected: Bool
    let trialDays: Int?
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: .spaceM) {
                SelectionMark(isSelected: isSelected)
                VStack(alignment: .leading, spacing: .space2XS) {
                    HStack(spacing: .spaceS) {
                        Text(plan.name).font(.rowTitle)
                        if plan.isBestValue { Chip("Best value", color: .retroOlive) }
                    }
                    Text(trialDays.map(plan.trial) ?? plan.periodPrice)
                        .font(.rowDetail)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: .space2XS) {
                    Text("\(plan.monthlyEquivalent ?? plan.product.displayPrice)/month")
                        .font(.rowTitle)
                    if let saving = plan.savingPercent {
                        Text("Save \(saving)%").font(.chipLabel).foregroundStyle(Color.retroOlive)
                    }
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.spaceL)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(
            isSelected ? appTint.opacity(.opacityFill) : .sheetCard,
            in: .rect(cornerRadius: .radiusL)
        )
        .overlay {
            RoundedRectangle(cornerRadius: .radiusL)
                .strokeBorder(isSelected ? appTint : .clear, lineWidth: .spaceHairline)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension PaywallPlan {
    var name: LocalizedStringKey {
        item == .proYearly ? "Annual" : "Monthly"
    }

    var periodPrice: LocalizedStringKey {
        product.period == .year
            ? "\(product.displayPrice)/year" : "\(product.displayPrice)/month"
    }

    var billing: LocalizedStringKey {
        product.period == .year
            ? "\(product.displayPrice)/year. Cancel anytime."
            : "\(product.displayPrice)/month. Cancel anytime."
    }

    var billingAfterTrial: LocalizedStringKey {
        product.period == .year
            ? "Then \(product.displayPrice)/year. Cancel anytime."
            : "Then \(product.displayPrice)/month. Cancel anytime."
    }

    func trial(_ days: Int) -> LocalizedStringKey {
        product.period == .year
            ? "\(days) days free, then \(product.displayPrice)/year"
            : "\(days) days free, then \(product.displayPrice)/month"
    }
}
