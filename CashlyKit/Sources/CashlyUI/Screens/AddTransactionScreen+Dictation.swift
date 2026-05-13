//
//  AddTransactionScreen+Dictation.swift
//  CashlyKit
//
//  Dictation handlers extracted from AddTransactionScreen.swift.
//  Pipeline: toggle mic → request auth → stream partial transcripts
//  → on final, hand the utterance to the parser → mutate state +
//  flip needsReview when fields are missing.
//

import SwiftUI
import CashlyDomain
import CashlyResource

extension AddTransactionScreen {
    @MainActor
    func toggleDictation() async {
        if isDictating {
            await stopDictation()
        } else {
            await startDictation()
        }
    }

    @MainActor
    private func startDictation() async {
        let status = await speechTranscriber.authorizationStatus()
        let authorized: SpeechAuthorization
        if status == .authorized {
            authorized = status
        } else {
            authorized = await speechTranscriber.requestAuthorization()
        }
        guard authorized == .authorized else { return }

        isDictating = true
        dictationInterim = ""

        do {
            let stream = try await speechTranscriber.startTranscription()
            var finalUtterance = ""
            for await transcript in stream {
                dictationInterim = transcript.text
                if transcript.isFinal { finalUtterance = transcript.text }
            }
            isDictating = false
            guard !finalUtterance.isEmpty else { return }
            await applyDraft(from: finalUtterance)
        } catch {
            isDictating = false
        }
    }

    @MainActor
    private func stopDictation() async {
        await speechTranscriber.stopTranscription()
        isDictating = false
    }

    @MainActor
    private func applyDraft(from utterance: String) async {
        let draft = await transactionDictation.parse(utterance)
        if let amount = draft.amount {
            store.cashlyMutate(\.amount, amount)
        }
        if let summary = draft.summary {
            store.cashlyMutate(\.summary, summary)
        }
        if let kind = draft.kind {
            store.cashlyMutate(\.kind, kind)
        }
        store.cashlyMutate(\.needsReview, draft.needsReview)
        if let name = draft.categoryName,
           let match = state.budgets.first(where: { $0.category.name.lowercased() == name.lowercased() }) {
            store.cashlyMutate(\.budget, match)
        }
        CashlyHaptic.success.play()
    }
}
