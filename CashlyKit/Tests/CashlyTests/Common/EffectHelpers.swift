//
//  EffectHelpers.swift
//  CashlyKit
//
//  Drain helper for PrismEffect so middleware tests can assert against
//  the produced action sequence.
//

import Foundation
import PrismArchitecture

/// Collects every action emitted by the effect's AsyncStream into an
/// array, returning when the stream finishes. Bounded by a 5s timeout
/// to keep tests from hanging on a stuck effect.
public func collectActions<Action: Sendable>(
    from effect: PrismEffect<Action>,
    timeout seconds: TimeInterval = 5
) async -> [Action] {
    await withTaskGroup(of: [Action].self) { group in
        group.addTask {
            var out: [Action] = []
            for await action in effect.actions {
                out.append(action)
            }
            return out
        }
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return []
        }
        if let first = await group.next() {
            group.cancelAll()
            return first
        }
        return []
    }
}
