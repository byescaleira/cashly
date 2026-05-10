//
//  CashlyPresentation.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 09/09/25.
//

import RyzeArchitecture

extension RyzeStore: @retroactive @unchecked Sendable {}

public typealias CashlyState = RyzeState
public typealias CashlyAction = RyzeAction
public typealias CashlyReducer = RyzeReducer
public typealias CashlyMiddleware = RyzeMiddleware
public typealias CashlyStore = RyzeStore
public typealias CashlyRoutable = RyzeRoutable
public typealias CashlyNavigationStyle = RyzeNavigationStyle
public typealias CashlyRouter = RyzeRouter
