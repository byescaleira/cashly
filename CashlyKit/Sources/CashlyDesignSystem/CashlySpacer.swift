//
//  CashlySpacer.swift
//  CashlyKit
//
//  //  Cashly-owned spacer. Thin wrapper around SwiftUI.Spacer.
//

import SwiftUI

public struct CashlySpacer: View {
    private let minLength: CGFloat?

    public init(minLength: CGFloat? = nil) {
        self.minLength = minLength
    }

    public var body: some View {
        Spacer(minLength: minLength)
    }
}
