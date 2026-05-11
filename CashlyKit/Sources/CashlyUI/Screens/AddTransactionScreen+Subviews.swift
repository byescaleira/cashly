//
//  AddTransactionScreen+Subviews.swift
//  CashlyKit
//
//  Reusable sub-views split out from AddTransactionScreen.swift (Wave 7 G019).
//

import SwiftUI
import CashlyResource
import CashlyDomain

extension AddTransactionScreen {
    @ViewBuilder
    var transactionStatusView: some View {
        if state.participants.isEmpty {
            Menu {
                Picker(selection: store.cashlyBinding(\.status)) {
                    ForEach(TransactionStatus.allCases) {
                        CashlyText($0.summary)
                            .tag($0)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                CashlyText(state.status.summary.uppercased())
                    .cashly(font: .caption, weight: .bold)
                    .cashly(color: .color(state.status.color))
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashly(glass: .clear.tint(state.status.color.opacity(0.2)).interactive(), in: .capsule)
            }
        }
    }

    @ViewBuilder
    var splitValueView: some View {
        let status = state.participants.first(where: { $0.status != .settled })?.status ?? .settled
        if !state.participants.isEmpty {
            CashlyText(state.splitValue?.currency())
                .cashly(font: .headline, weight: .semibold)
                .cashly(color: .color(status.color))
                .contentTransition(.numericText())
                .animation(.linear, value: store.state.splitValue)
                .cashlyPadding()
                .cashlyPadding(.horizontal, .extraSmall)
                .cashly(glass: .clear.tint(status.color.opacity(0.2)), in: .capsule)
        }
    }

    @ViewBuilder
    var tagsView: some View {
        CashlyZStack {
            if !state.summaryTags.isEmpty {
                CashlyHorizontalList { _ in
                    CashlyHStack {
                        ForEach(state.summaryTags) { tag in
                            CashlyHStack {
                                CashlySymbol(tag.icon)
                                CashlyText(tag.name.uppercased())
                            }
                            .cashly(font: .footnote, weight: .semibold)
                            .cashly(color: .hex(tag.color))
                            .cashlyPadding()
                            .cashlyPadding(.horizontal, .extraSmall)
                            .cashly(
                                glass: .clear.tint(Color(hex: tag.color).opacity(0.2)),
                                in: .capsule
                            )
                            .transition(.move(edge: .top).animation(.bouncy.speed(0.2)))
                        }
                    }
                }
                .frame(height: 50)
                .padding(.horizontal, -40)
            }
        }
        .animation(.bouncy, value: state.summaryTags)
    }

    @ViewBuilder
    var categoriesView: some View {
        if !state.categories.isEmpty {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.categories) { category in
                        categoryItemView(category: category)
                            .id(category)
                    }
                }
                .onChange(of: state.category) {
                    Task {
                        try await Task.sleep(for: .seconds(0.2))
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(state.category, anchor: .center)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    var splitModeView: some View {
        return CashlyHStack {
            CashlyText(CashlyL10n.string("Select Split Mode"))

            CashlySpacer()

            Menu {
                Picker(selection: store.cashlyBinding(\.splitMode)) {
                    ForEach(TransactionSplitMode.allCases) {
                        CashlyText($0.summary)
                            .tag($0)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                CashlyText(state.splitMode?.summary.uppercased())
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .primary)
                    .cashlyPadding()
                    .cashlyPadding(.horizontal, .extraSmall)
                    .cashly(glass: .clear.tint(.accentColor.opacity(0.2)), in: .capsule)
            }
        }
    }

    var participantsView: some View {
        Section {
            ForEach(Array(store.state.participants).enumerated(), id: \.offset) { index, participant in
                ParticipantRowView(
                    participant: participantBinding(at: index),
                    splitMode: state.splitMode,
                    amount: state.amount,
                    count: state.participants.count
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    CashlyButton(role: .destructive) {
                        if let index = state.participants.firstIndex(of: participant) {
                            store.state.participants.remove(at: index)
                        }
                    } label: {
                        CashlyLabel(CashlyL10n.string("Delete"), symbol: "trash.fill")
                    }
                    .cashly(tint: .error)
                }
                .onChange(of: participant.splitValue) { updateSplitValue() }
            }
        }
    }
}
