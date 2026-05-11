//
//  AddCategoryScreen+Sections.swift
//  CashlyKit
//
//  Form sections for AddCategoryScreen.
//

import SwiftUI
import CashlyResource
import CashlyDomain
import CashlyPresentation

extension AddCategoryScreen {
    var infoSection: some View {
        Section {} header: {
            iconHeaderView
        }
    }

    var nameSection: some View {
        Section {
            TextField(
                "Enter the category name",
                text: store.cashlyBinding(\.name)
            )
        } header: {
            CashlyText(CashlyL10n.string("Name"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        }
    }

    var iconCategorySection: some View {
        Section {
            CashlyHStack {
                CashlyText(CashlyL10n.string("Category"))

                CashlySpacer()

                Menu {
                    Picker(selection: $category) {
                        ForEach(CashlySymbolCategory.allCases, id: \.self) {
                            CashlyText($0.name)
                                .tag($0)
                        }
                    } label: {
                        CashlyText(category.name)
                    }
                } label: {
                    CashlyHStack {
                        CashlyText(category.name)
                            .cashly(font: .body, weight: .semibold)
                        CashlySymbol("chevron.up.chevron.down")
                            .cashly(font: .footnote, weight: .semibold)
                    }
                }
                .cashly(tint: .color(Color(hex: state.color)))
            }
        } header: {
            CashlyText(CashlyL10n.string("Icon"))
                .cashly(font: .title3, weight: .semibold)
                .cashly(color: .text)
        } footer: {
            CashlyHorizontalList { proxy in
                CashlyHStack(spacing: .zero) {
                    ForEach(category.symbols, id: \.self) { icon in
                        iconItemView(item: icon)
                            .cashlyPadding()
                    }
                }
                .onChange(of: state.icon) {
                    Task {
                        try await Task.sleep(for: .seconds(0.2))
                        withAnimation(.bouncy.speed(0.5)) {
                            proxy.scrollTo(state.icon, anchor: .center)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.horizontal, -40)
        }
    }
}
