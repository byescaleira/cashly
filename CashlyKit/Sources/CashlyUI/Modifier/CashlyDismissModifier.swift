//
//  CashlyDismissModifier.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 11/09/25.
//

import SwiftUI

struct CashlyDismissModifier: ViewModifier {
    @Environment(\.router) var router

    var isSaved: Bool = false

    func body(content: Content) -> some View {
        content
            .onChange(of: isSaved) { onChangeSaved() }
    }

    func onChangeSaved() {
        guard isSaved else { return }
        router.dismiss()
    }
}
