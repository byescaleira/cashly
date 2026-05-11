//
//  CashlyMenuSelectionView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyResource

struct CashlyMenuSelectionView<T: Identifiable & Hashable>: View {
    var items: [T]
    @Binding var selectedItems: Set<T>
    let content: (T) -> any View
    let label: any View
    
    init(
        items: [T],
        selectedItems: Binding<Set<T>>,
        @ViewBuilder content: @escaping (T) -> some View,
        @ViewBuilder label: () -> some View,
    ) {
        self.items = items
        self._selectedItems = selectedItems
        self.content = content
        self.label = label()
    }
    
    var body: some View {
        Menu {
            contentView
            
            if !selectedItems.isEmpty {
                Divider()
                CashlyButton {
                    selectedItems = []
                } label: {
                    CashlyLabel(CashlyL10n.string("Clean"), symbol: "eraser.line.dashed")
                }
            }
        } label: {
            AnyView(label)
        }
    }
    
    var contentView: some View {
        ForEach(items) { item in
            let contains = selectedItems.contains(item)
            CashlyButton {
                if contains {
                    selectedItems.remove(item)
                } else {
                    selectedItems.insert(item)
                }
            } label: {
                CashlyHStack(spacing: .zero) {
                    if contains { CashlySymbol("checkmark") }
                    AnyView(content(item))
                }
            }
        }
    }
}
