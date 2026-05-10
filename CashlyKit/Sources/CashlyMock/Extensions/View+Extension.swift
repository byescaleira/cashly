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
    static func cashlyPreview() -> some View {
        mocked().modifier(MockModifier())
    }
}

public extension View {
    func cashlyPreview() -> some View {
        self.modifier(MockModifier())
    }
}
