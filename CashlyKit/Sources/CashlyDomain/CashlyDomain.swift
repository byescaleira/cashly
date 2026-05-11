//
//  CashlyTypealias.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

@_exported import PrismFoundation

/// Cashly's domain entity protocol. Refines PrismEntity with Identifiable
/// because most Cashly use cases (lists, pickers, ForEach) rely on the
/// entity-as-Identifiable convention that RyzeEntity bundled.
public protocol CashlyEntity: PrismEntity, Identifiable, Sendable {}

