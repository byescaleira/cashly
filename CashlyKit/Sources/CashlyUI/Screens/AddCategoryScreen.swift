//
//  AddCategoryScreen.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import CashlyMock
import CashlyDomain
import CashlyPresentation

public struct AddCategoryScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<AddCategoryReducer, AddCategoryMiddleware>
    
    public init() {}
    
    public var body: some View {
        CashlyList {
            
        }
        
    }
    
    public static var mock: some View {
        AddCategoryScreen()
    }
}

#Preview {
    AddCategoryScreen
        .mock
        .cashlyPreview()
}
