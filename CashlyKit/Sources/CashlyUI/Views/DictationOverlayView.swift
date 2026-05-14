//
//  DictationOverlayView.swift
//  CashlyKit
//
//  Banner shown while AddTransactionScreen is capturing speech.
//  Renders interim transcripts as they arrive so the user sees the
//  recognizer keeping up. Pulses a dot icon while the engine is
//  still listening; freezes once the engine emits a final result.
//

import SwiftUI
import CashlyResource
import CashlyDesignSystem

public struct DictationOverlayView: View {
    let text: String
    let isListening: Bool

    @State private var pulse: Bool = false

    public init(text: String, isListening: Bool) {
        self.text = text
        self.isListening = isListening
    }

    public var body: some View {
        CashlyHStack(spacing: .small) {
            CashlySymbol(isListening ? "waveform" : "checkmark")
                .cashly(color: .color(isListening ? .red : .green))
                .cashly(font: .body, weight: .bold)
                .scaleEffect(pulse && isListening ? 1.15 : 1.0)
                .animation(
                    isListening
                        ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                        : .default,
                    value: pulse
                )
                .accessibilityHidden(true)

            CashlyVStack(alignment: .leading, spacing: .extraSmall) {
                CashlyText(CashlyL10n.string(isListening ? "Listening…" : "Done"))
                    .cashly(font: .caption, weight: .semibold)
                    .cashly(color: .textSecondary)
                CashlyText(text.isEmpty ? CashlyL10n.string("Speak your transaction") : text)
                    .cashly(font: .callout)
                    .lineLimit(2)
            }
            CashlySpacer()
        }
        .cashlyPadding(.all, .medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cashlyPadding(.horizontal, .medium)
        .cashlyPadding(.top, .small)
        .onAppear { pulse = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(CashlyL10n.string(isListening ? "Listening…" : "Done")): \(text)"
        )
    }
}
