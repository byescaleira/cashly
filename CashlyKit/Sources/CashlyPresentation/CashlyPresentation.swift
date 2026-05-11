//
//  CashlyPresentation.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 09/09/25.
//

import RyzeArchitecture
@_exported import CashlyDesignSystem

extension RyzeStore: @retroactive @unchecked Sendable {}

public typealias CashlyState = RyzeState
public typealias CashlyAction = RyzeAction
public typealias CashlyReducer = RyzeReducer
public typealias CashlyMiddleware = RyzeMiddleware
public typealias CashlyStore = RyzeStore
// CashlyRoutable/CashlyNavigationStyle/CashlyRouter: Cashly-owned
// in CashlyDesignSystem, re-exported above.
