//
//  View+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI
import CashlyDesignSystem

public extension View where Self: CashlyView {
    static func cashlyPreview() -> some View {
        mocked().modifier(MockModifier())
    }
}

public extension View {
    func cashlyPreview() -> some View {
        self.modifier(MockModifier())
    }
}
