//
//  IsLoadingEnvironment.swift
//  CashlyKit
//
//  Wave 5a: Cashly-owned `\.isLoading` env value. Replaces the
//  RyzeUI-provided key consumed by CashlyText/CashlyLabel/CashlySymbol.
//

import SwiftUI

private struct CashlyIsLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    var isLoading: Bool {
        get { self[CashlyIsLoadingKey.self] }
        set { self[CashlyIsLoadingKey.self] = newValue }
    }
}
