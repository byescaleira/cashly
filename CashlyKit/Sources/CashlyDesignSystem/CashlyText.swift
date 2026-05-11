//
//  CashlyText.swift
//  CashlyKit
//

import SwiftUI

/// A text primitive that renders a redacted skeleton while the
/// surrounding view hierarchy reports `\.isLoading == true`.
///
/// Pass a non-nil `String` to render normally; pass `nil` together
/// with an active loading state to display a sized placeholder that
/// keeps row heights stable while data loads.
///
/// ```swift
/// CashlyText(user?.name)
///     .environment(\.isLoading, state.isLoading)
/// ```
public struct CashlyText: View {
    @Environment(\.isLoading) private var isLoading

    private let text: String?

    /// Creates a text view from an optional string.
    /// - Parameter text: The string to render, or `nil` to render only
    ///   the skeleton placeholder.
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
