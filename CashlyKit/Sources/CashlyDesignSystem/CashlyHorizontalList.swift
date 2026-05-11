//
//  CashlyHorizontalList.swift
//  CashlyKit
//
//  //  Cashly-owned horizontal scroller. Wraps ScrollViewReader +
//  ScrollView(.horizontal) and exposes the proxy to the content closure.
//

import SwiftUI

public struct CashlyHorizontalList<Content: View>: View {
    private let content: (ScrollViewProxy) -> Content
    @State private var position: Int?

    public init(@ViewBuilder content: @escaping (ScrollViewProxy) -> Content) {
        self.content = content
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                content(proxy)
            }
            .scrollIndicators(.hidden)
            .scrollPosition(id: $position)
        }
    }
}
