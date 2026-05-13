//
//  CashlyHaptic.swift
//  CashlyKit
//
//  Centralised haptic feedback. SwiftUI's `.sensoryFeedback` exists
//  on iOS 17+ but is awkward to thread through reusable buttons; this
//  enum + helper play once on demand via UIImpactFeedbackGenerator /
//  UINotificationFeedbackGenerator. macOS path is a no-op.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

public enum CashlyHaptic: Sendable {
    /// Selection change — tab swap, picker move.
    case selection
    /// Light bump — save committed, button tap.
    case success
    /// Strong bump — destructive confirmation (wipe, delete).
    case warning
    /// Sharp bump — failure / error alert surfaced.
    case error

    @MainActor
    public func play() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        switch self {
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}
