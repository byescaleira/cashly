//
//  InMemoryAppIconService.swift
//  CashlyKit
//
//  Stub `AppIconUseCase` used on platforms without UIApplication
//  (macOS today) and by tests / previews. Kept in CashlyData so
//  the factory can fall back to it via `#if canImport(UIKit)`
//  without the Mock target leaking into Release builds.
//

import Foundation
import CashlyDomain

public actor InMemoryAppIconService: AppIconUseCase {
    private var current: AppIcon

    public init(initial: AppIcon = .primary) {
        self.current = initial
    }

    public func currentIcon() async -> AppIcon { current }

    @discardableResult
    public func setIcon(_ icon: AppIcon) async -> Bool {
        current = icon
        return true
    }
}
