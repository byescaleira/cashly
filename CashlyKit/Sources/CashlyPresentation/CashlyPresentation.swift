//
//  CashlyPresentation.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 09/09/25.
//

import PrismArchitecture
@_exported import CashlyDesignSystem

/// Marker protocol for State types stored in a ``CashlyStore``.
public typealias CashlyState = PrismState

/// Marker protocol for Action types dispatched into a ``CashlyStore``.
public typealias CashlyAction = PrismAction

/// `@MainActor` reducer protocol — pure `reduce(into:action:) ->
/// PrismEffect<Action>`.
public typealias CashlyReducer = PrismReducer

/// Side-effect protocol — `run(state:action:) ->
/// PrismEffect<Action>` returning `PrismEffect.run { send in ... }`
/// for async work against domain use cases.
public typealias CashlyMiddleware = PrismMiddleware

/// `@MainActor @Observable` store generic over `<State, Action>`.
/// State is `private(set)`; views write through
/// ``PrismArchitecture/PrismStore/cashlyBinding(_:)``,
/// ``PrismArchitecture/PrismStore/cashlyMutate(_:_:)``, and
/// ``PrismArchitecture/PrismStore/cashlyReplace(_:)``.
public typealias CashlyStore = PrismStore
// CashlyRoutable/CashlyNavigationStyle/CashlyRouter: Cashly-owned
// in CashlyDesignSystem, re-exported above.
