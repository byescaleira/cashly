//
//  DictationEnvironment.swift
//  CashlyKit
//
//  Environment-injected dictation use cases. CashlyApp installs the
//  production impls; previews + tests install the InMemory pair.
//  Lets AddTransactionScreen reach the parser + transcriber without
//  hard-wiring CashlyDataFactory.
//

import SwiftUI
import CashlyDomain
import CashlyData

private struct DictationParserKey: EnvironmentKey {
    static let defaultValue: TransactionDictationUseCase = KeywordTransactionDictation()
}

private struct SpeechTranscriberKey: EnvironmentKey {
    static let defaultValue: SpeechTranscriberUseCase = InMemorySpeechTranscriber(authorization: .unavailable)
}

private struct AttachmentStorageKey: EnvironmentKey {
    static let defaultValue: AttachmentStorageUseCase = InMemoryAttachmentStorage()
}

public extension EnvironmentValues {
    var transactionDictation: TransactionDictationUseCase {
        get { self[DictationParserKey.self] }
        set { self[DictationParserKey.self] = newValue }
    }

    var speechTranscriber: SpeechTranscriberUseCase {
        get { self[SpeechTranscriberKey.self] }
        set { self[SpeechTranscriberKey.self] = newValue }
    }

    var attachmentStorage: AttachmentStorageUseCase {
        get { self[AttachmentStorageKey.self] }
        set { self[AttachmentStorageKey.self] = newValue }
    }
}
