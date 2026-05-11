//
//  CashlyText.swift
//  CashlyKit
//
//  Wave 5b: Cashly-owned text primitive backed by SwiftUI.Text.
//  Reads `\.isLoading` from the upstream environment to apply a
//  redacted placeholder skeleton.
//

import SwiftUI
import RyzeUI

public struct CashlyText: View {
    @Environment(\.isLoading) private var isLoading

    private let text: String?

    public init(_ text: String?) {
        self.text = text
    }

    @ViewBuilder
    public var body: some View {
        if isLoading {
            Text(text ?? Self.placeholder)
                .redacted(reason: .placeholder)
        } else if let text {
            Text(text)
        }
    }

    /// Filler used when isLoading is true and text is nil. Keeps the
    /// skeleton sized realistically.
    static let placeholder: String = "Loading preview"
}
