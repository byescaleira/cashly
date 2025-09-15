//
//  FilterItemView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 08/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyPresentation
import CashlyMock

struct FilterItemView: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    
    var body: some View {
        Menu {
            
        } label: {
            CashlySymbol("slider.horizontal.3")
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }
    
    static var mock: some View {
        FilterItemView()
    }
}

#Preview {
    NavigationView {
        CashlyList {
            
        }
        .toolbar { FilterItemView.cashlyPreview() }
    }
    .cashly(tint: .primary)
}
