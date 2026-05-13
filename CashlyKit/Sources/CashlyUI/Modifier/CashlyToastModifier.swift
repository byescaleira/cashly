//
//  CashlyToastModifier.swift
//  CashlyKit
//
//  Lightweight transient toast banner. Bound to an `isPresented`
//  Bool — when it flips to true a card slides in from the top with
//  the supplied message and auto-dismisses after `duration` seconds.
//  Use for non-critical feedback (restore returned nothing, copy to
//  clipboard, etc.). For errors keep using cashlyErrorAlert.
//

import SwiftUI
import CashlyResource

public struct CashlyToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let message: String
    let duration: TimeInterval
    /// Monotonic id incremented every time `isPresented` flips to
    /// true. The auto-dismiss `.task` keys off this so a stale
    /// sleep from a previous appearance can't dismiss a newer one.
    @State private var generation: Int = 0

    public func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue { generation &+= 1 }
            }
            .overlay(alignment: .top) {
                if isPresented {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .accessibilityHidden(true)
                        Text(message)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85), in: .capsule)
                    .padding(.top, 12)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    // Combine inner views so VoiceOver reads "Nothing
                    // to restore." as a single announcement rather
                    // than reading the decorative icon and message
                    // separately.
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(message)
                    .accessibilityAddTraits(.isStaticText)
                    .task(id: generation) {
                        guard isPresented else { return }
                        let myGeneration = generation
                        try? await Task.sleep(for: .seconds(duration))
                        // If a new generation has started in the
                        // meantime, this sleep is stale — don't
                        // touch the binding.
                        guard myGeneration == generation else { return }
                        withAnimation(reduceMotion ? nil : .default) { isPresented = false }
                    }
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isPresented)
    }
}

public extension View {
    /// Present a transient toast banner when `isPresented` flips
    /// to true. Auto-dismisses after `duration` (3s default).
    func cashlyToast(
        isPresented: Binding<Bool>,
        message: String,
        duration: TimeInterval = 3
    ) -> some View {
        modifier(CashlyToastModifier(
            isPresented: isPresented,
            message: message,
            duration: duration
        ))
    }
}
