import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureStore
import SwiftUI

struct PlanSwitchScreen: View {
    @Environment(StoreModel.self) private var store
    @State private var contentHeight: CGFloat = 360
    @State private var barHeight: CGFloat = 120
    let change: PlanSwitch

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: .spaceXL) {
                    PlanSwitchTopBar()
                    PlanSwitchHero(change: change)
                    PlanSwitchPriceCard(change: change)
                }
                .padding(.horizontal, .spaceInset)
                .padding(.bottom, .spaceXL)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    contentHeight = $0
                }
            }
            .readableWidth()
            PlanSwitchBar(change: change)
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: {
                    barHeight = $0
                }
        }
        .fontDesign(.rounded)
        .presentationDetents([.height(contentHeight + barHeight)])
        .presentationDragIndicator(.hidden)
        #if !os(visionOS)
            .presentationBackground(.sheetBackground)
        #endif
        .interactiveDismissDisabled(store.isBuying)
        .errorAlert($store.error)
        #if os(macOS)
            .frame(minWidth: 480, minHeight: 420)
        #endif
    }
}

private struct PlanSwitchTopBar: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Spacer()
            Button("Close", systemImage: "xmark") { dismiss() }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.circle)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(store.isBuying)
        }
        .frame(height: .badgeL)
        .padding(.top, .spaceS)
    }
}

private struct PlanSwitchHero: View {
    let change: PlanSwitch

    var body: some View {
        VStack(spacing: .spaceM) {
            CashlyAnimationView(.pro).frame(maxWidth: 260)
            Text(verbatim: change.title).font(.titleLarge)
            Text(verbatim: change.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Chip(change.planName, color: .retroMustard, shape: .capsule)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

private struct PlanSwitchPriceCard: View {
    let change: PlanSwitch

    var body: some View {
        HStack(spacing: .spaceM) {
            VStack(alignment: .leading, spacing: .space2XS) {
                Text(verbatim: change.planName).font(.rowTitle)
                Text(verbatim: change.fact).font(.rowDetail).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: change.price)
                .font(.amountRow)
                .foregroundStyle(Color.retroMustard)
        }
        .padding(.spaceL)
        .background(Color.retroMustard.opacity(.opacityFill), in: .rect(cornerRadius: .radiusL))
        .accessibilityElement(children: .combine)
    }
}

private struct PlanSwitchBar: View {
    @Environment(StoreModel.self) private var store
    @Environment(\.dismiss) private var dismiss
    let change: PlanSwitch

    var body: some View {
        VStack(spacing: .spaceS) {
            Button {
                Task { if await store.switchPlan() { dismiss() } }
            } label: {
                ZStack {
                    Text(verbatim: change.action).opacity(store.isBuying ? 0 : 1)
                    if store.isBuying { ProgressView() }
                }
            }
            .primaryButton()
            .disabled(store.isBuying)
            .accessibilityIdentifier("pro.switch.confirm")
            Button("Not Now") { dismiss() }
                .font(.buttonLabel)
                .buttonStyle(.borderless)
                .disabled(store.isBuying)
            StorePolicyLinks()
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, .spaceInset)
        .padding(.top, .spaceS)
        .padding(.bottom, .spaceM)
    }
}
