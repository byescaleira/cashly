//
//  View+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import RyzeUI
import RyzeArchitecture

public extension View where Self: RyzeUIMock {
    func cashlyPreview() -> some View {
        self.modifier(MockModifier())
    }
    
    static func cashlyPreview() -> some View {
        mock.modifier(MockModifier())
    }
}
