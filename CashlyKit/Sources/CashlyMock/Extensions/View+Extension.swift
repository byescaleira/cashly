//
//  View+Extension.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import SwiftUI

public extension View {
    func cashlyPreview() -> some View {
        self.modifier(MockModifier())
    }
}
