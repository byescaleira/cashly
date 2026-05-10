//
//  HomeScreen+Tags.swift
//  CashlyKit
//
//  Wave 7 G019: Tags section extracted from HomeScreen.swift.
//

import SwiftUI
import CashlyDomain

extension HomeScreen {
    @ViewBuilder
    var tagsSection: some View {
        EmptyTagView()

        if !state.tags.isEmpty {
            Section {
                let data: [(String, Double)] = state.tags.map {
                    let amount = state.transactionsAmount(for: $0)
                    return ($0.name.capitalized, amount)
                }

                if let selectedTag {
                    let amount = data.first(where: { $0.0 == selectedTag.name })?.1

                    CashlyButton {
                        router.route(to: .addTag(state: .edit(id: selectedTag.id)))
                    } label: {
                        CashlyHStack {
                            CashlyText(selectedTag.name.uppercased())
                                .cashly(font: .caption2, weight: .bold)
                                .cashly(color: .hex(selectedTag.color))
                                .cashlyPadding()
                                .cashlyPadding(.horizontal, .extraSmall)
                                .cashly(glass: .clear.tint(.init(hex: selectedTag.color).opacity(0.2)).interactive(), in: .capsule)

                            CashlySpacer()

                            CashlyText(amount?.currency())
                                .cashly(font: .title3, weight: .bold)
                                .cashly(color: .text)
                                .contentTransition(.numericText())

                            CashlySymbol("chevron.forward")
                                .cashly(color: .disabled)
                        }
                        .animation(.bouncy, value: amount)
                    }
                    .cashly(tint: .text)
                }

                CashlyChart(
                    type: .line,
                    startItemsAmount: 4.5,
                    data: data
                )

                CashlyButton {
                    router.route(to: .addTag(state: .new()))
                } label: {
                    CashlyHStack {
                        CashlyText("Add new tag")
                        CashlySpacer()
                        CashlySymbol("chevron.forward")
                            .cashly(color: .disabled)
                    }
                }
                .cashly(tint: .text)
            } header: {
                CashlyVStack(alignment: .leading, spacing: .small) {
                    CashlyText("Tags")
                        .cashly(font: .title3, weight: .semibold)
                        .cashly(color: .text)

                    tagsView
                }
                .frame(maxWidth: .infinity)
                .cashly(alignment: .leading)
            }
        }
    }

    var tagsView: some View {
        CashlyVStack(alignment: .leading, spacing: .small) {
            CashlyHorizontalList { proxy in
                CashlyHStack {
                    ForEach(state.tags) { tag in
                        CashlyButton {
                            selectedTag = tag
                        } label: {
                            CashlySymbol(tag.icon)
                                .cashly(font: .system(size: 20))
                                .cashly(color: selectedTag == tag ? .hex(tag.color) : .color(.secondary))
                                .frame(width: 45, height: 45)
                                .cashly(background: .color((selectedTag == tag ? Color(hex: tag.color) : .secondary).opacity(0.2)))
                                .cashly(clip: .circle)
                                .overlay {
                                    Circle()
                                        .stroke(selectedTag == tag ? Color(hex: tag.color) : .secondary, lineWidth: 3)
                                        .frame(width: 50, height: 50)
                                }
                                .opacity(selectedTag == tag ? 1 : 0.3)
                                .cashly(if: tag == selectedTag) {
                                    $0.cashly(symbol: .bounce.byLayer, options: .repeat(.continuous).speed(0.1))
                                }
                        }
                        .id(tag)
                        .cashlyPadding()
                    }
                }
                .onChange(of: selectedTag) {
                    Task {
                        try await Task.sleep(for: .seconds(0.2))
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(selectedTag, anchor: .center)
                        }
                    }
                }
                .animation(.bouncy, value: selectedTag)
                .padding(.horizontal, 40)
            }
            .onAppear { selectedTag = selectedTag == nil ? state.tags.first : selectedTag }
            .padding(.horizontal, -40)
        }
    }
}
