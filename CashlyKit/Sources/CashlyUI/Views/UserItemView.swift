//
//  UserItemView.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftUI
import CashlyDomain
import CashlyPresentation
import CashlyMock

struct UserItemView: CashlyView {
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    
    var body: some View {
        
    }
    
    static var mock: some View {
        UserItemView()
    }
}

#Preview {
    UserItemView
        .cashlyPreview()
}
