//
//  ManageCategoriesScreen.swift
//  CashlyKit
//
//  Drag-reorder + delete UI for categories. Pushed from Settings.
//  Persists order changes by dispatching MainAction.reorderCategories
//  with the new id sequence.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct ManageCategoriesScreen: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.action) var action

    public init() {}

    public var body: some View {
        List {
            ForEach(state.categories, id: \.id) { category in
                CashlyHStack(spacing: .small) {
                    CashlySymbol(category.icon)
                        .cashly(color: .hex(category.color))
                        .cashly(font: .body)
                    CashlyText(category.name.capitalized)
                        .cashly(font: .callout)
                }
            }
            .onMove { source, destination in
                var ids = state.categories.map(\.id)
                ids.move(fromOffsets: source, toOffset: destination)
                action(.main(.reorderCategories(ids)))
                CashlyHaptic.selection.play()
            }
        }
        .navigationTitle(CashlyL10n.string("Categories"))
        #if os(iOS)
        .toolbar { EditButton() }
        #endif
    }

    public static var mock: some View {
        ManageCategoriesScreen()
    }
}
