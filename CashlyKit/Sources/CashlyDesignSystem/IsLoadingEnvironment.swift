//
//  IsLoadingEnvironment.swift
//  CashlyKit
//
//  Cashly-owned `\.isLoading` environment value consumed by
//  CashlyText / CashlyLabel / CashlySymbol to render redacted
//  skeletons while data is in flight.
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
