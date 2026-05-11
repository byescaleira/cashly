//
//  AddCategoryScreen+Subviews.swift
//  CashlyKit
//
//  Icon item button + animated header for AddCategoryScreen.
//

import SwiftUI
import CashlyResource

extension AddCategoryScreen {
    func iconItemView(item: String) -> some View {
        CashlyButton {
            store.cashlyMutate(\.icon, item)
        } label: {
            CashlySymbol(item)
                .cashly(font: .system(size: 18))
                .cashly(color: item == state.icon ? .color(Color(hex: state.color)) : .color(.gray))
                .frame(width: 40, height: 40)
                .cashly(background: item == state.icon ? .color(Color(hex: state.color).opacity(0.2)) : .color(.gray.opacity(0.2)))
                .cashly(clip: .circle)
                .overlay {
                    if item == state.icon {
                        Circle()
                            .stroke(Color(hex: state.color), lineWidth: 2)
                            .frame(width: 45, height: 45)
                    }
                }
                .cashly(if: item == state.icon) {
                    $0.cashly(
                        symbol: .bounce.byLayer,
                        options: .repeat(.continuous).speed(0.1)
                    )
                }
        }
        .buttonStyle(.plain)
    }

    var iconHeaderView: some View {
        CashlySymbol(state.icon, mode: .hierarchical)
            .cashly(font: .system(size: 50))
            .cashly(
                symbol: .bounce.byLayer,
                options: .repeat(.continuous).speed(0.1)
            )
            .cashly(color: .color(Color(hex: state.color)))
            .frame(width: 120, height: 120)
            .cashly(background: .color(Color(hex: state.color).opacity(0.2)))
            .cashly(clip: .circle)
            .overlay {
                Circle()
                    .stroke(Color(hex: state.color), lineWidth: 5)
                    .cashlyPadding(.negative(.small))
            }
            .overlay(alignment: .bottomTrailing) {
                ColorPicker("", selection: Binding(
                    get: { Color(hex: store.state.color) },
                    set: { store.cashlyMutate(\.color, $0.hex) }
                ))
                    .scaleEffect(1.5)
                    .cashlyPadding(.trailing, .large )
            }
            .frame(maxWidth: .infinity)
            .contentTransition(.symbolEffect(.replace))
            .cashlyPadding(.top, .medium)
    }
}
