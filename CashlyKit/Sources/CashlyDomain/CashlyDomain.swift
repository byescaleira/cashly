//
//  CashlyDomain.swift
//  CashlyKit
//

@_exported import PrismFoundation

/// Domain entity protocol. Refines `PrismEntity` with `Identifiable`
/// + `Sendable` because Cashly use cases (lists, pickers, ForEach,
/// cross-actor effects) assume both.
public protocol CashlyEntity: PrismEntity, Identifiable, Sendable {}

