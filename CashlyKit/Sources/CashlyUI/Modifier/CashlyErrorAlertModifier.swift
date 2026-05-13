//
//  CashlyErrorAlertModifier.swift
//  CashlyKit
//
//  Surfaces a CashlyError stored in state. Domain `.featureGated`
//  errors don't get an alert — they push the paywall sheet via the
//  router instead. Every other error becomes a native SwiftUI alert
//  with the typed `errorDescription` / `failureReason` /
//  `recoverySuggestion`. Tapping OK clears the error in the store via
//  the supplied reset closure.
//

import SwiftUI
import CashlyDomain
import CashlyResource
import CashlyPresentation

public struct CashlyErrorAlertModifier: ViewModifier {
    @Environment(\.router) private var router

    private let error: CashlyError?
    private let reset: () -> Void

    public init(
        error: CashlyError?,
        reset: @escaping () -> Void
    ) {
        self.error = error
        self.reset = reset
    }

    public func body(content: Content) -> some View {
        content
            .onChange(of: alertId) { _, _ in
                handlePaywallIfNeeded()
                if alertableError != nil { CashlyHaptic.error.play() }
            }
            .alert(
                title,
                isPresented: presentationBinding,
                presenting: alertableError
            ) { error in
                Button(CashlyL10n.string("OK")) { reset() }
            } message: { error in
                CashlyText(message(for: error))
            }
    }

    /// Identity used to detect a *new* error landing — re-fires
    /// onChange even when the previous error was the same case.
    private var alertId: String {
        error.map(String.init(describing:)) ?? ""
    }

    private var presentationBinding: Binding<Bool> {
        Binding(
            get: { alertableError != nil },
            set: { presented in
                if !presented { reset() }
            }
        )
    }

    /// Only errors that should land as an alert. `.featureGated` is
    /// routed to the paywall via `handlePaywallIfNeeded()` and is
    /// suppressed from the alert surface.
    private var alertableError: CashlyError? {
        guard let error else { return nil }
        if case .domain(.featureGated) = error { return nil }
        return error
    }

    private var title: String {
        guard let error else { return "" }
        return error.errorDescription ?? CashlyL10n.string("Something went wrong.")
    }

    private func message(for error: CashlyError) -> String {
        var parts: [String] = []
        if let reason = error.failureReason { parts.append(reason) }
        if let recovery = error.recoverySuggestion { parts.append(recovery) }
        return parts.joined(separator: "\n\n")
    }

    private func handlePaywallIfNeeded() {
        guard case .domain(.featureGated) = error else { return }
        router.route(to: .paywall(trigger: .limitReached))
        // Reset so re-presenting the same feature gate re-fires.
        reset()
    }
}

public extension View {
    /// Surface a `CashlyError?` as a native alert. `.featureGated`
    /// instead pushes the paywall via the active router.
    func cashlyErrorAlert(
        error: CashlyError?,
        reset: @escaping () -> Void
    ) -> some View {
        modifier(CashlyErrorAlertModifier(error: error, reset: reset))
    }
}
