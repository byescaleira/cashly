//
//  CashlyDesignSystem.swift
//  CashlyKit
//
//  Wave 5b: vocabulary layer for Cashly UI. Currently re-exports Ryze
//  types via typealiases; in Wave 5b/5d, swap re-exports to Prism +
//  Cashly-owned wrappers without touching call sites in CashlyUI.
//

@_exported import SwiftUI
import RyzeUI
import RyzeArchitecture

public typealias CashlyColor = RyzeColor
public typealias CashlySize = RyzeSize
public typealias CashlySpacing = RyzeSpacing
public typealias CashlyShape = RyzeShape
public typealias CashlyView = RyzeView
// CashlySpacer: Cashly-owned struct (see CashlySpacer.swift).
public typealias CashlyButton = RyzeButton
public typealias CashlySection = RyzeSection
public typealias CashlyHStack = RyzeHStack
public typealias CashlyVStack = RyzeVStack
public typealias CashlyZStack = RyzeZStack
// CashlySymbol: Cashly-owned struct (see CashlySymbol.swift).
// CashlyText: Cashly-owned struct (see CashlyText.swift). No longer a Ryze typealias.
public typealias CashlyTextField = RyzeTextField
public typealias CashlyCurrencyTextField = RyzeCurrencyTextField
public typealias CashlyTextFieldConfiguration = RyzeTextFieldConfiguration
public typealias CashlyList = RyzeList
public typealias CashlyHorizontalList = RyzeHorizontalList
public typealias CashlyAsyncImage = RyzeAsyncImage
public typealias CashlyLabel = RyzeLabel
public typealias CashlyBrowserView = RyzeBrowserView
public typealias CashlyLocale = RyzeLocale
public typealias CashlyNavigationView = RyzeNavigationView
public typealias CashlySystemMonitor = RyzeSystemMonitor

public extension RyzeView {
    @MainActor
    static func mocked() -> some View {
        EmptyView()
    }
}
